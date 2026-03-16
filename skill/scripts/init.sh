#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════╗
# ║  Projector — Init Script                          ║
# ║  Bootstraps standalone or hub mode                ║
# ╚══════════════════════════════════════════════════╝
#
# Usage:
#   bash init.sh                            → Interactive guided setup
#   bash init.sh --standalone               → Standalone (creates .projector/ here)
#   bash init.sh --hub <org-name>           → Hub (validates GitHub org, creates hub)
#   bash init.sh --hub <org-name> <project> → Creates a project inside the hub

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATES_DIR="${SKILL_DIR}/templates"
DATE=$(date '+%Y-%m-%d')
PROJECTS_ROOT="${HOME}/Projects"

# ── Load .env if exists (never read by agent, only by script) ──
ENV_FILE="${SKILL_DIR}/.env"
if [ -f "${ENV_FILE}" ]; then
  set -a
  source "${ENV_FILE}"
  set +a
fi
# Also check local .env
if [ -f "${PWD}/.env" ]; then
  set -a
  source "${PWD}/.env"
  set +a
fi

# Apply env overrides
[ -n "${PROJECTOR_HUB_DIR:-}" ] && PROJECTS_ROOT="$(dirname "${PROJECTOR_HUB_DIR}")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log()     { echo -e "${BLUE}[projector]${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
error()   { echo -e "${RED}✗${NC} $1" >&2; }

# ── Open in browser (cross-platform) ──
open_browser() {
  local file="$1"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$file"
  elif command -v xdg-open &> /dev/null; then
    xdg-open "$file"
  elif command -v wslview &> /dev/null; then
    wslview "$file"
  else
    log "Abre manualmente: ${CYAN}${file}${NC}"
    return
  fi
  success "Abierto en el navegador"
}

# ── Sync content.js from .md ──
sync_content_js() {
  local MD_FILE="$1"
  local DIR=$(dirname "$MD_FILE")
  local CONTENT_JS="${DIR}/content.js"
  if [ ! -f "$MD_FILE" ]; then
    error "No se encontró: $MD_FILE"
    return 1
  fi
  python3 - "$MD_FILE" "$CONTENT_JS" << 'PYEOF'
import sys
md_path, js_path = sys.argv[1], sys.argv[2]
with open(md_path, 'r') as f:
    md = f.read()
# Escape for JS template literal
md = md.replace('\\', '\\\\').replace('`', '\\`').replace('$', '\\$')
with open(js_path, 'w') as f:
    f.write('window.__MD_CONTENT = `' + md + '`;\n')
PYEOF
  success "content.js sincronizado: ${CONTENT_JS}"
}

# ── Validate GitHub org ──
validate_github_org() {
  local ORG_NAME="$1"

  if ! command -v gh &> /dev/null; then
    warn "GitHub CLI (gh) no instalado. Omitiendo validación."
    warn "Instálalo con: ${CYAN}brew install gh${NC}"
    return 0
  fi

  if ! gh auth status &> /dev/null; then
    error "No estás autenticado en GitHub CLI."
    error "Ejecuta: ${CYAN}gh auth login${NC}"
    return 1
  fi

  log "Validando organización '${BOLD}${ORG_NAME}${NC}' en GitHub..."
  if ! gh api "orgs/${ORG_NAME}" --silent 2>/dev/null; then
    error "La organización '${ORG_NAME}' no existe en GitHub."
    echo ""
    echo -e "  ${BOLD}¿Cómo crear una organización en GitHub?${NC}"
    echo ""
    echo -e "  ${CYAN}1.${NC} Ve a ${CYAN}https://github.com/organizations/plan${NC}"
    echo -e "  ${CYAN}2.${NC} Selecciona el plan ${BOLD}Free${NC} (o el que prefieras)"
    echo -e "  ${CYAN}3.${NC} Nombre de la organización: ${BOLD}${ORG_NAME}${NC}"
    echo -e "  ${CYAN}4.${NC} Email de contacto: tu email"
    echo -e "  ${CYAN}5.${NC} Selecciona '${BOLD}My personal account${NC}' como propietario"
    echo -e "  ${CYAN}6.${NC} Completa la verificación y crea la organización"
    echo ""
    echo -e "  ${DIM}Una vez creada, configura tu .env:${NC}"
    echo -e "  ${CYAN}cp .env.example .env${NC}"
    echo -e "  ${DIM}Agrega: ${CYAN}PROJECTOR_ORG=${ORG_NAME}${NC}"
    echo ""
    echo -e "  ${DIM}Luego vuelve a ejecutar:${NC}"
    echo -e "  ${CYAN}bash init.sh --hub ${ORG_NAME}${NC}"
    echo ""
    return 1
  fi
  success "Organización '${ORG_NAME}' encontrada"

  local ROLE
  ROLE=$(gh api "orgs/${ORG_NAME}/memberships/$(gh api user -q .login)" -q '.role' 2>/dev/null || echo "none")

  if [[ "$ROLE" == "admin" || "$ROLE" == "member" ]]; then
    success "Acceso verificado (rol: ${BOLD}${ROLE}${NC})"
  elif [[ "$ROLE" == "none" ]]; then
    if gh api "orgs/${ORG_NAME}/repos" --silent 2>/dev/null; then
      warn "No se pudo verificar tu rol, pero tienes acceso."
    else
      error "No tienes acceso a la organización '${ORG_NAME}'."
      return 1
    fi
  fi

  return 0
}

# ── Interactive Guided Setup ──
interactive_setup() {
  echo ""
  echo -e "${BOLD}📐 Projector — Setup Guiado${NC}"
  echo -e "${DIM}   Documento técnico interactivo SDLC${NC}"
  echo ""

  # Step 1: Choose mode
  echo -e "${BOLD}¿Qué tipo de proyecto quieres crear?${NC}"
  echo ""
  echo -e "  ${CYAN}1)${NC} ${BOLD}Organización${NC} (hub multi-proyecto, como GitHub)"
  echo -e "     ${DIM}Gestiona múltiples proyectos en un dashboard central${NC}"
  echo ""
  echo -e "  ${CYAN}2)${NC} ${BOLD}Proyecto standalone${NC}"
  echo -e "     ${DIM}Documento técnico para el proyecto actual${NC}"
  echo ""
  read -r -p "$(echo -e "  Selecciona [${CYAN}1${NC}/${CYAN}2${NC}]: ")" MODE_CHOICE
  echo ""

  case "${MODE_CHOICE}" in
    1)
      guided_hub
      ;;
    2)
      guided_standalone
      ;;
    *)
      error "Opción no válida. Usa 1 o 2."
      exit 1
      ;;
  esac
}

# ── Guided Hub Setup ──
guided_hub() {
  # Step 2: Org name
  # Pre-fill from .env if available
  local DEFAULT_ORG="${PROJECTOR_ORG:-}"

  echo -e "${BOLD}¿Cuál es el nombre de la organización en GitHub?${NC}"
  echo -e "  ${DIM}(ejemplo: condolab-app, mi-empresa, etc.)${NC}"
  if [ -n "${DEFAULT_ORG}" ]; then
    read -r -p "$(echo -e "  Organización [${CYAN}${DEFAULT_ORG}${NC}]: ")" ORG_NAME
    ORG_NAME="${ORG_NAME:-${DEFAULT_ORG}}"
  else
    read -r -p "$(echo -e "  Organización: ${CYAN}")" ORG_NAME
    echo -ne "${NC}"
  fi
  echo ""

  if [ -z "${ORG_NAME}" ]; then
    error "El nombre de la organización no puede estar vacío."
    exit 1
  fi

  # Step 3: Directory location
  local DEFAULT_DIR="${PROJECTS_ROOT}/${ORG_NAME}"
  echo -e "${BOLD}¿Dónde quieres crear el hub?${NC}"
  echo ""
  echo -e "  ${CYAN}1)${NC} ${DEFAULT_DIR} ${DIM}(recomendado)${NC}"
  echo -e "  ${CYAN}2)${NC} Directorio actual (${PWD})"
  echo -e "  ${CYAN}3)${NC} Otra ubicación"
  echo ""
  read -r -p "$(echo -e "  Selecciona [${CYAN}1${NC}/${CYAN}2${NC}/${CYAN}3${NC}]: ")" DIR_CHOICE
  echo ""

  local HUB_DIR
  case "${DIR_CHOICE}" in
    1)
      HUB_DIR="${DEFAULT_DIR}"
      ;;
    2)
      HUB_DIR="${PWD}/${ORG_NAME}"
      ;;
    3)
      read -r -p "$(echo -e "  Ruta completa: ${CYAN}")" HUB_DIR
      echo -ne "${NC}"
      ;;
    *)
      HUB_DIR="${DEFAULT_DIR}"
      ;;
  esac

  echo ""

  # Validate org
  if ! validate_github_org "${ORG_NAME}"; then
    exit 1
  fi

  echo ""
  log "Creando hub en ${CYAN}${HUB_DIR}${NC}"

  mkdir -p "${HUB_DIR}/projects"

  if [ ! -f "${HUB_DIR}/index.html" ]; then
    cp "${TEMPLATES_DIR}/dashboard.html" "${HUB_DIR}/index.html"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/Projector/Projector · ${ORG_NAME}/g" "${HUB_DIR}/index.html"
    else
      sed -i "s/Projector/Projector · ${ORG_NAME}/g" "${HUB_DIR}/index.html"
    fi
    success "Dashboard creado"
  else
    log "Dashboard ya existe, no se sobreescribe"
  fi

  success "Hub '${ORG_NAME}' listo en: ${HUB_DIR}"
  echo ""

  # Step 4: Create first project?
  read -r -p "$(echo -e "  ${BOLD}¿Quieres crear el primer proyecto ahora?${NC} [${CYAN}s${NC}/${CYAN}n${NC}]: ")" CREATE_PROJECT

  if [[ "${CREATE_PROJECT}" =~ ^[sS]$ ]]; then
    echo ""
    read -r -p "$(echo -e "  Nombre del proyecto: ${CYAN}")" PROJ_NAME
    echo -ne "${NC}"
    read -r -p "$(echo -e "  Descripción breve:   ${CYAN}")" PROJ_DESC
    echo -ne "${NC}"
    echo ""

    create_hub_project_with_dir "${HUB_DIR}" "${PROJ_NAME}" "${PROJ_DESC}"
  else
    open_browser "${HUB_DIR}/index.html"
  fi

  echo ""
  echo -e "  ${BOLD}Próximos pasos:${NC}"
  echo -e "    Con Antigravity:  ${CYAN}/software-design hub${NC}"
  echo -e "    Crear proyecto:   ${CYAN}bash init.sh --hub ${ORG_NAME} <nombre> <descripción>${NC}"
  echo ""
}

# ── Guided Standalone ──
guided_standalone() {
  local TARGET_DIR="${PWD}/.projector"

  echo -e "${BOLD}Se creará el documento técnico en:${NC}"
  echo -e "  ${CYAN}${TARGET_DIR}/technical-design.html${NC}"
  echo ""
  read -r -p "$(echo -e "  ${BOLD}¿Continuar?${NC} [${CYAN}s${NC}/${CYAN}n${NC}]: ")" CONFIRM

  if [[ ! "${CONFIRM}" =~ ^[sS]$ ]]; then
    log "Cancelado."
    exit 0
  fi

  echo ""
  init_standalone_core
}

# ── Hub Mode (non-interactive) ──
init_hub() {
  local ORG_NAME="$1"
  local HUB_DIR="${PROJECTS_ROOT}/${ORG_NAME}"

  echo ""
  echo -e "${BOLD}📐 Projector — Inicializando Organización${NC}"
  echo ""

  if ! validate_github_org "${ORG_NAME}"; then
    exit 1
  fi

  echo ""
  log "Creando hub en ${CYAN}${HUB_DIR}${NC}"

  mkdir -p "${HUB_DIR}/projects"

  if [ ! -f "${HUB_DIR}/index.html" ]; then
    cp "${TEMPLATES_DIR}/dashboard.html" "${HUB_DIR}/index.html"
    success "Dashboard creado: ${HUB_DIR}/index.html"
  else
    log "Dashboard ya existe, no se sobreescribe"
  fi

  # Create metadata.json
  if [ ! -f "${HUB_DIR}/metadata.js" ]; then
    cat > "${HUB_DIR}/metadata.js" <<EOF
window.__PROJECTOR_META = {
  "organization": "${ORG_NAME}",
  "created": "${DATE}",
  "github": "https://github.com/${ORG_NAME}",
  "projects": []
};
EOF
    success "Metadata creado: ${HUB_DIR}/metadata.js"
  fi

  success "Hub '${ORG_NAME}' listo en: ${HUB_DIR}"
  echo ""
  open_browser "${HUB_DIR}/index.html"
  echo ""
  echo -e "  ${BOLD}Crear proyecto:${NC}     ${CYAN}bash init.sh --hub ${ORG_NAME} <nombre> <descripción>${NC}"
  echo -e "  ${BOLD}Con Antigravity:${NC}    ${CYAN}/software-design hub${NC}"
  echo ""
}

# ── Hub: Create Project ──
create_hub_project_with_dir() {
  local HUB_DIR="$1"
  local PROJECT_NAME="$2"
  local PROJECT_DESC="${3:-}"
  local PROJECT_DIR="${HUB_DIR}/projects/${PROJECT_NAME}"

  log "Creando proyecto '${PROJECT_NAME}'"

  mkdir -p "${PROJECT_DIR}"

  if [ ! -f "${PROJECT_DIR}/technical-design.md" ]; then
    # Copy Markdown template (source of truth)
    cp "${TEMPLATES_DIR}/technical-design.md" "${PROJECT_DIR}/technical-design.md"
    # Copy viewer
    cp "${TEMPLATES_DIR}/viewer.html" "${PROJECT_DIR}/index.html"

    # Replace placeholders in .md
    local f="${PROJECT_DIR}/technical-design.md"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" "$f"
      sed -i '' "s/{{PROJECT_DESCRIPTION}}/${PROJECT_DESC}/g" "$f"
      sed -i '' "s/{{DATE}}/${DATE}/g" "$f"
    else
      sed -i "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" "$f"
      sed -i "s/{{PROJECT_DESCRIPTION}}/${PROJECT_DESC}/g" "$f"
      sed -i "s/{{DATE}}/${DATE}/g" "$f"
    fi

    # Generate content.js from .md
    sync_content_js "${PROJECT_DIR}/technical-design.md"

    success "Proyecto creado: ${PROJECT_DIR}/"

    # Update metadata.js
    local META="${HUB_DIR}/metadata.js"
    if [ -f "${META}" ] && command -v python3 &> /dev/null; then
      python3 <<PYEOF
import json, re
with open('${META}','r') as f: content=f.read()
match = re.search(r'window\.__PROJECTOR_META\s*=\s*({.*});', content, re.DOTALL)
if match:
    data = json.loads(match.group(1))
    data['projects'].append({'name':'${PROJECT_NAME}','description':'${PROJECT_DESC}','status':'active','created':'${DATE}','phase':0,'phases':9})
    with open('${META}','w') as f:
        f.write('window.__PROJECTOR_META = ' + json.dumps(data, indent=2, ensure_ascii=False) + ';\n')
PYEOF
      success "Metadata actualizado"
    fi

    open_browser "${PROJECT_DIR}/index.html"
  else
    log "El proyecto '${PROJECT_NAME}' ya existe"
  fi
}

# ── Link existing repo into hub ──
link_existing_repo() {
  local ORG_NAME="$1"
  local REPO_PATH="$(cd "$2" 2>/dev/null && pwd)"  # resolve absolute path
  local DESC="${3:-}"

  if [ ! -d "$REPO_PATH" ]; then
    error "Directorio no encontrado: $2"
    exit 1
  fi

  local REPO_NAME=$(basename "$REPO_PATH")
  local DATE=$(date +%Y-%m-%d)
  local HUB_DIR="${PROJECTS_ROOT}/${ORG_NAME}"

  if [ ! -d "$HUB_DIR" ]; then
    error "Hub no encontrado: $HUB_DIR"
    echo -e "  Primero crea el hub: ${CYAN}bash init.sh --hub ${ORG_NAME}${NC}"
    exit 1
  fi

  # If no description, try to get from git remote or use default
  if [ -z "$DESC" ]; then
    DESC=$(cd "$REPO_PATH" && git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||' || echo "Proyecto")
    DESC="Proyecto ${REPO_NAME}"
  fi

  log "Vinculando '${REPO_NAME}' desde ${CYAN}${REPO_PATH}${NC}"

  # Create .projector inside the repo
  local PROJECTOR_DIR="${REPO_PATH}/.projector"
  mkdir -p "${PROJECTOR_DIR}"

  if [ ! -f "${PROJECTOR_DIR}/technical-design.md" ]; then
    cp "${TEMPLATES_DIR}/technical-design.md" "${PROJECTOR_DIR}/technical-design.md"
    cp "${TEMPLATES_DIR}/viewer.html" "${PROJECTOR_DIR}/index.html"

    # Replace placeholders
    local f="${PROJECTOR_DIR}/technical-design.md"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/{{PROJECT_NAME}}/${REPO_NAME}/g" "$f"
      sed -i '' "s/{{PROJECT_DESCRIPTION}}/${DESC}/g" "$f"
      sed -i '' "s/{{DATE}}/${DATE}/g" "$f"
    else
      sed -i "s/{{PROJECT_NAME}}/${REPO_NAME}/g" "$f"
      sed -i "s/{{PROJECT_DESCRIPTION}}/${DESC}/g" "$f"
      sed -i "s/{{DATE}}/${DATE}/g" "$f"
    fi

    sync_content_js "${PROJECTOR_DIR}/technical-design.md"
    success "Documentos creados en ${REPO_NAME}/.projector/"
  else
    log "Ya existe .projector/ en ${REPO_NAME}, no se sobreescribe"
  fi

  # Create symlink in hub
  local LINK_PATH="${HUB_DIR}/projects/${REPO_NAME}"
  if [ ! -e "$LINK_PATH" ]; then
    ln -s "${PROJECTOR_DIR}" "$LINK_PATH"
    success "Symlink creado: projects/${REPO_NAME} → ${REPO_PATH}/.projector"
  else
    log "Link ya existe: projects/${REPO_NAME}"
  fi

  # Update metadata.js
  local META="${HUB_DIR}/metadata.js"
  if [ -f "${META}" ] && command -v python3 &> /dev/null; then
    python3 <<PYEOF
import json, re
with open('${META}','r') as f: content=f.read()
match = re.search(r'window\.__PROJECTOR_META\s*=\s*({.*});', content, re.DOTALL)
if match:
    data = json.loads(match.group(1))
    # Check if already registered
    if not any(p['name'] == '${REPO_NAME}' for p in data['projects']):
        data['projects'].append({'name':'${REPO_NAME}','description':'${DESC}','status':'active','created':'${DATE}','phase':0,'phases':9,'linked':'${REPO_PATH}'})
        with open('${META}','w') as f:
            f.write('window.__PROJECTOR_META = ' + json.dumps(data, indent=2, ensure_ascii=False) + ';\n')
PYEOF
    success "Metadata actualizado"
  fi

  echo ""
  echo -e "  Abrir visor:   ${CYAN}python3 -m http.server 8765 --directory ${HUB_DIR}${NC}"
  echo -e "  Luego:         ${CYAN}http://localhost:8765/projects/${REPO_NAME}/index.html${NC}"
  echo ""
}

# ── Scan local directory as hub ──
scan_local_hub() {
  local HUB_PATH="$(cd "$1" 2>/dev/null && pwd)"
  if [ ! -d "$HUB_PATH" ]; then
    error "Directorio no encontrado: $1"
    exit 1
  fi

  local HUB_NAME=$(basename "$HUB_PATH")
  local DATE=$(date +%Y-%m-%d)

  echo ""
  echo -e "${BOLD}📐 Projector — Escaneando directorio local${NC}"
  echo ""
  log "Hub: ${CYAN}${HUB_PATH}${NC} (${HUB_NAME})"

  # Create hub infrastructure if not exists
  mkdir -p "${HUB_PATH}/projects"

  if [ ! -f "${HUB_PATH}/index.html" ]; then
    cp "${TEMPLATES_DIR}/dashboard.html" "${HUB_PATH}/index.html"
  fi

  # Create or update metadata
  local META="${HUB_PATH}/metadata.js"
  if [ ! -f "$META" ]; then
    cat > "$META" << METAEOF
window.__PROJECTOR_META = {
  "org": "${HUB_NAME}",
  "github": "",
  "created": "${DATE}",
  "projects": []
};
METAEOF
    success "Dashboard + metadata creados"
  fi

  # Scan for repos — check both top-level and projects/ subdirectory
  local COUNT=0

  _init_repo_in_scan() {
    local dir="$1"
    local HUB_PATH="$2"
    local META="$3"
    local DATE="$4"
    local IS_IN_PROJECTS="$5"  # "yes" if already inside projects/

    [ ! -d "$dir" ] && return
    local REPO_NAME=$(basename "$dir")
    # Skip internal dirs
    [ "$REPO_NAME" = "projects" ] && return
    [ "$REPO_NAME" = ".projector" ] && return
    [ "$REPO_NAME" = ".agents" ] && return

    # Check if it's a repo (has .git or has source files)
    if [ ! -d "${dir}/.git" ] && [ ! -f "${dir}/package.json" ] && [ ! -f "${dir}/go.mod" ] && [ ! -f "${dir}/Cargo.toml" ]; then
      return
    fi

    log "Encontrado: ${CYAN}${REPO_NAME}${NC}"

    # Get description from git or default
    local DESC=""
    if [ -d "${dir}/.git" ]; then
      DESC=$(cd "$dir" && git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||' || echo "")
    fi
    [ -z "$DESC" ] && DESC="Proyecto ${REPO_NAME}"

    # Create .projector inside repo
    local PROJ_DIR="${dir}/.projector"
    mkdir -p "$PROJ_DIR"

    if [ ! -f "${PROJ_DIR}/technical-design.md" ]; then
      cp "${TEMPLATES_DIR}/technical-design.md" "${PROJ_DIR}/technical-design.md"
      cp "${TEMPLATES_DIR}/viewer.html" "${PROJ_DIR}/index.html"

      local f="${PROJ_DIR}/technical-design.md"
      if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/{{PROJECT_NAME}}/${REPO_NAME}/g" "$f"
        sed -i '' "s/{{PROJECT_DESCRIPTION}}/${DESC}/g" "$f"
        sed -i '' "s/{{DATE}}/${DATE}/g" "$f"
      else
        sed -i "s/{{PROJECT_NAME}}/${REPO_NAME}/g" "$f"
        sed -i "s/{{PROJECT_DESCRIPTION}}/${DESC}/g" "$f"
        sed -i "s/{{DATE}}/${DATE}/g" "$f"
      fi

      sync_content_js "${PROJ_DIR}/technical-design.md"
      success "  → .projector/ creado en ${REPO_NAME}"
    else
      log "  → .projector/ ya existe en ${REPO_NAME}"
    fi

    # Install workflow (for /software-design command)
    local WORKFLOW_DIR="${dir}/.agents/workflows"
    if [ ! -f "${WORKFLOW_DIR}/software-design.md" ]; then
      mkdir -p "$WORKFLOW_DIR"
      local WF_SRC="${SKILL_DIR}/workflows/software-design.md"
      if [ -f "$WF_SRC" ]; then
        cp "$WF_SRC" "${WORKFLOW_DIR}/software-design.md"
        success "  → workflow instalado en ${REPO_NAME}/.agents/"
      fi
    fi

    # If repo is NOT inside projects/, symlink the whole .projector dir
    if [ "$IS_IN_PROJECTS" != "yes" ]; then
      local LINK="${HUB_PATH}/projects/${REPO_NAME}"
      if [ ! -e "$LINK" ]; then
        ln -s "${PROJ_DIR}" "$LINK"
      fi
    else
      # Repo IS inside projects/ — create file symlinks at repo root
      for vfile in index.html content.js technical-design.md; do
        if [ -f "${PROJ_DIR}/${vfile}" ] && [ ! -e "${dir}/${vfile}" ]; then
          ln -s ".projector/${vfile}" "${dir}/${vfile}"
        fi
      done
    fi

    # Add to metadata if not present
    if command -v python3 &> /dev/null; then
      python3 - "$META" "$REPO_NAME" "$DESC" "$DATE" << 'PYEOF'
import json, re, sys
meta_path, name, desc, date = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(meta_path, 'r') as f: content = f.read()
match = re.search(r'window\.__PROJECTOR_META\s*=\s*({.*});', content, re.DOTALL)
if match:
    data = json.loads(match.group(1))
    if not any(p['name'] == name for p in data['projects']):
        data['projects'].append({'name': name, 'description': desc, 'status': 'active', 'created': date, 'phase': 0, 'phases': 9})
        with open(meta_path, 'w') as f:
            f.write('window.__PROJECTOR_META = ' + json.dumps(data, indent=2, ensure_ascii=False) + ';\n')
PYEOF
    fi

    COUNT=$((COUNT + 1))
  }

  # Scan top-level directories
  for dir in "${HUB_PATH}"/*/; do
    local dname=$(basename "$dir")
    [ "$dname" = "projects" ] && continue
    _init_repo_in_scan "$dir" "$HUB_PATH" "$META" "$DATE" "no"
  done

  # Scan inside projects/ if it exists
  if [ -d "${HUB_PATH}/projects" ]; then
    for dir in "${HUB_PATH}"/projects/*/; do
      _init_repo_in_scan "$dir" "$HUB_PATH" "$META" "$DATE" "yes"
    done
  fi

  success "${COUNT} proyectos registrados en el hub '${HUB_NAME}'"
  echo ""
  echo -e "  ${BOLD}Abrir dashboard:${NC}  ${CYAN}python3 -m http.server 8765 --directory ${HUB_PATH}${NC}"
  echo -e "  ${BOLD}Luego abrir:${NC}      ${CYAN}http://localhost:8765${NC}"
  echo ""
}

create_hub_project() {
  local ORG_NAME="$1"
  local PROJECT_NAME="$2"
  local PROJECT_DESC="${3:-}"
  local HUB_DIR="${PROJECTS_ROOT}/${ORG_NAME}"

  if [ ! -f "${HUB_DIR}/index.html" ]; then
    error "El hub '${ORG_NAME}' no existe. Inicialízalo primero:"
    error "  bash init.sh --hub ${ORG_NAME}"
    exit 1
  fi

  create_hub_project_with_dir "${HUB_DIR}" "${PROJECT_NAME}" "${PROJECT_DESC}"
  echo ""
}

# ── Standalone Core ──
init_standalone_core() {
  local TARGET_DIR="${PWD}/.projector"

  log "Inicializando Projector en ${CYAN}${TARGET_DIR}${NC}"

  mkdir -p "${TARGET_DIR}"

  if [ ! -f "${TARGET_DIR}/technical-design.md" ]; then
    cp "${TEMPLATES_DIR}/technical-design.md" "${TARGET_DIR}/technical-design.md"
    cp "${TEMPLATES_DIR}/viewer.html" "${TARGET_DIR}/index.html"
    sync_content_js "${TARGET_DIR}/technical-design.md"
    success "Projector inicializado: .md + viewer"
    open_browser "${TARGET_DIR}/index.html"
  else
    log "Documento técnico ya existe, no se sobreescribe"
  fi

  success "Projector listo"
  echo ""
  echo -e "  Iniciar flujo:    ${CYAN}/software-design${NC}"
  echo ""
}

# ── Main ──
case "${1:-}" in
  --hub)
    if [ -z "${2:-}" ]; then
      error "Debes especificar el nombre de la organización."
      echo ""
      echo -e "  Uso: ${CYAN}bash init.sh --hub <org-name>${NC}"
      echo -e "        ${CYAN}bash init.sh --hub <org-name> <project> <description>${NC}"
      echo ""
      exit 1
    fi
    if [ -n "${3:-}" ]; then
      create_hub_project "$2" "$3" "${4:-}"
    else
      init_hub "$2"
    fi
    ;;
  --sync)
    if [ -z "${2:-}" ]; then
      error "Debes especificar la ruta al archivo .md"
      echo ""
      echo -e "  Uso: ${CYAN}bash init.sh --sync <ruta/technical-design.md>${NC}"
      echo ""
      exit 1
    fi
    sync_content_js "$2"
    ;;
  --link)
    if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
      error "Faltan argumentos"
      echo ""
      echo -e "  Uso: ${CYAN}bash init.sh --link <org> <ruta-al-repo> [descripción]${NC}"
      echo ""
      echo "Ejemplos:"
      echo "  bash init.sh --link condolab-app ~/Projects/clusterflux"
      echo "  bash init.sh --link condolab-app ~/Projects/clusterflux \"Plataforma de clusters\""
      echo ""
      exit 1
    fi
    link_existing_repo "$2" "$3" "${4:-}"
    ;;
  --scan)
    if [ -z "${2:-}" ]; then
      error "Debes especificar la ruta al directorio"
      echo ""
      echo -e "  Uso: ${CYAN}bash init.sh --scan <ruta/al/directorio>${NC}"
      echo ""
      exit 1
    fi
    scan_local_hub "$2"
    ;;
  --standalone)
    init_standalone_core
    ;;
  --help|-h)
    echo ""
    echo -e "${BOLD}Projector — Documento Técnico SDLC${NC}"
    echo ""
    echo "Uso:"
    echo "  bash init.sh                                  Setup guiado (interactivo)"
    echo "  bash init.sh --standalone                     Standalone (crea .projector/ aquí)"
    echo "  bash init.sh --hub <org>                      Inicializa hub (GitHub org)"
    echo "  bash init.sh --hub <org> <project> <desc>     Crea proyecto en el hub"
    echo "  bash init.sh --scan <path>                    Escanea directorio local como hub"
    echo "  bash init.sh --link <org> <path> [desc]       Vincula un repo al hub"
    echo "  bash init.sh --sync <path/file.md>            Regenera content.js"
    echo ""
    echo "Ejemplos:"
    echo "  bash init.sh"
    echo "  bash init.sh --hub condolab-app"
    echo "  bash init.sh --scan ~/Projects/clusterflux"
    echo "  bash init.sh --link condolab-app ~/Projects/my-repo"
    echo ""
    ;;
  *)
    interactive_setup
    ;;
esac
