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
    error "Créala en: ${CYAN}https://github.com/organizations/plan${NC}"
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
  echo -e "${BOLD}¿Cuál es el nombre de la organización en GitHub?${NC}"
  echo -e "  ${DIM}(ejemplo: condolab-app, mi-empresa, etc.)${NC}"
  read -r -p "$(echo -e "  Organización: ${CYAN}")" ORG_NAME
  echo -ne "${NC}"
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
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/Projector/Projector · ${ORG_NAME}/g" "${HUB_DIR}/index.html"
    else
      sed -i "s/Projector/Projector · ${ORG_NAME}/g" "${HUB_DIR}/index.html"
    fi
    success "Dashboard creado: ${HUB_DIR}/index.html"
  else
    log "Dashboard ya existe, no se sobreescribe"
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

  if [ ! -f "${PROJECT_DIR}/technical-design.html" ]; then
    cp "${TEMPLATES_DIR}/technical-design.html" "${PROJECT_DIR}/technical-design.html"

    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" "${PROJECT_DIR}/technical-design.html"
      sed -i '' "s/{{PROJECT_DESCRIPTION}}/${PROJECT_DESC}/g" "${PROJECT_DIR}/technical-design.html"
      sed -i '' "s/{{DATE}}/${DATE}/g" "${PROJECT_DIR}/technical-design.html"
    else
      sed -i "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" "${PROJECT_DIR}/technical-design.html"
      sed -i "s/{{PROJECT_DESCRIPTION}}/${PROJECT_DESC}/g" "${PROJECT_DIR}/technical-design.html"
      sed -i "s/{{DATE}}/${DATE}/g" "${PROJECT_DIR}/technical-design.html"
    fi

    success "Documento técnico creado: ${PROJECT_DIR}/technical-design.html"
    open_browser "${PROJECT_DIR}/technical-design.html"
  else
    log "El proyecto '${PROJECT_NAME}' ya existe"
  fi
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

  if [ ! -f "${TARGET_DIR}/technical-design.html" ]; then
    cp "${TEMPLATES_DIR}/technical-design.html" "${TARGET_DIR}/technical-design.html"
    success "Template copiado a ${TARGET_DIR}/technical-design.html"
    open_browser "${TARGET_DIR}/technical-design.html"
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
    echo "  bash init.sh --hub <org>                      Inicializa hub para una organización"
    echo "  bash init.sh --hub <org> <project> <desc>     Crea proyecto en el hub"
    echo ""
    echo "Ejemplos:"
    echo "  bash init.sh"
    echo "  bash init.sh --hub condolab-app"
    echo "  bash init.sh --hub condolab-app mi-api \"API de autenticación\""
    echo ""
    ;;
  *)
    interactive_setup
    ;;
esac
