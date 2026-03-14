#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════╗
# ║  Projector — Init Script                          ║
# ║  Bootstraps standalone or hub mode                ║
# ╚══════════════════════════════════════════════════╝
#
# Usage:
#   bash init.sh                            → Standalone (creates .projector/ here)
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
  success "Dashboard abierto en el navegador"
}

# ── Validate GitHub org ──
validate_github_org() {
  local ORG_NAME="$1"
  
  # Check gh CLI
  if ! command -v gh &> /dev/null; then
    warn "GitHub CLI (gh) no instalado. Omitiendo validación de organización."
    warn "Instálalo con: ${CYAN}brew install gh${NC}"
    return 0
  fi
  
  # Check auth
  if ! gh auth status &> /dev/null; then
    error "No estás autenticado en GitHub CLI."
    error "Ejecuta: ${CYAN}gh auth login${NC}"
    return 1
  fi
  
  # Check org exists
  log "Validando organización '${BOLD}${ORG_NAME}${NC}' en GitHub..."
  if ! gh api "orgs/${ORG_NAME}" --silent 2>/dev/null; then
    error "La organización '${ORG_NAME}' no existe en GitHub."
    error "Créala en: ${CYAN}https://github.com/organizations/plan${NC}"
    return 1
  fi
  success "Organización '${ORG_NAME}' encontrada"
  
  # Check write access (try to list repos — if it works, we have at least read access)
  local ROLE
  ROLE=$(gh api "orgs/${ORG_NAME}/memberships/$(gh api user -q .login)" -q '.role' 2>/dev/null || echo "none")
  
  if [[ "$ROLE" == "none" ]]; then
    # Fallback: check if we can list repos (public orgs allow this)
    if gh api "orgs/${ORG_NAME}/repos" --silent 2>/dev/null; then
      warn "No se pudo verificar tu rol, pero tienes acceso a la organización."
    else
      error "No tienes acceso a la organización '${ORG_NAME}'."
      return 1
    fi
  elif [[ "$ROLE" == "admin" || "$ROLE" == "member" ]]; then
    success "Acceso verificado (rol: ${BOLD}${ROLE}${NC})"
  else
    warn "Rol desconocido: ${ROLE}. Continuando..."
  fi
  
  return 0
}

# ── Hub Mode ──
init_hub() {
  local ORG_NAME="$1"
  local HUB_DIR="${PROJECTS_ROOT}/${ORG_NAME}"
  
  echo ""
  echo -e "${BOLD}📐 Projector — Inicializando Organización${NC}"
  echo ""
  
  # Validate GitHub org
  if ! validate_github_org "${ORG_NAME}"; then
    exit 1
  fi
  
  echo ""
  log "Creando hub en ${CYAN}${HUB_DIR}${NC}"
  
  mkdir -p "${HUB_DIR}/projects"
  
  if [ ! -f "${HUB_DIR}/index.html" ]; then
    cp "${TEMPLATES_DIR}/dashboard.html" "${HUB_DIR}/index.html"
    
    # Replace org name in dashboard title
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
  
  # Auto-open in browser
  open_browser "${HUB_DIR}/index.html"
  
  echo ""
  echo -e "  ${BOLD}Crear proyecto:${NC}     ${CYAN}bash init.sh --hub ${ORG_NAME} <nombre> <descripción>${NC}"
  echo -e "  ${BOLD}Con Antigravity:${NC}    ${CYAN}/software-design hub${NC}"
  echo ""
}

# ── Hub: Create Project ──
create_hub_project() {
  local ORG_NAME="$1"
  local PROJECT_NAME="$2"
  local PROJECT_DESC="${3:-}"
  local HUB_DIR="${PROJECTS_ROOT}/${ORG_NAME}"
  local PROJECT_DIR="${HUB_DIR}/projects/${PROJECT_NAME}"
  
  # Verify hub exists
  if [ ! -f "${HUB_DIR}/index.html" ]; then
    error "El hub '${ORG_NAME}' no existe. Inicialízalo primero:"
    error "  bash init.sh --hub ${ORG_NAME}"
    exit 1
  fi
  
  log "Creando proyecto '${PROJECT_NAME}' en ${ORG_NAME}"
  
  mkdir -p "${PROJECT_DIR}"
  
  if [ ! -f "${PROJECT_DIR}/technical-design.html" ]; then
    cp "${TEMPLATES_DIR}/technical-design.html" "${PROJECT_DIR}/technical-design.html"
    
    # Replace placeholders
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
    
    # Auto-open project document
    open_browser "${PROJECT_DIR}/technical-design.html"
  else
    log "El proyecto '${PROJECT_NAME}' ya existe"
  fi
  
  echo ""
}

# ── Standalone Mode ──
init_standalone() {
  local TARGET_DIR="${PWD}/.projector"
  
  log "Inicializando Projector en ${CYAN}${TARGET_DIR}${NC}"
  
  mkdir -p "${TARGET_DIR}"
  
  if [ ! -f "${TARGET_DIR}/technical-design.html" ]; then
    cp "${TEMPLATES_DIR}/technical-design.html" "${TARGET_DIR}/technical-design.html"
    success "Template copiado a ${TARGET_DIR}/technical-design.html"
    
    # Auto-open
    open_browser "${TARGET_DIR}/technical-design.html"
  else
    log "Documento técnico ya existe, no se sobreescribe"
  fi
  
  success "Projector listo en: ${TARGET_DIR}"
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
  --help|-h)
    echo ""
    echo -e "${BOLD}Projector — Documento Técnico SDLC${NC}"
    echo ""
    echo "Uso:"
    echo "  bash init.sh                                  Standalone (crea .projector/ aquí)"
    echo "  bash init.sh --hub <org>                      Inicializa hub para una organización"
    echo "  bash init.sh --hub <org> <project> <desc>     Crea proyecto en el hub"
    echo ""
    echo "Ejemplos:"
    echo "  bash init.sh --hub condolab-app"
    echo "  bash init.sh --hub condolab-app mi-api \"API de autenticación\""
    echo ""
    ;;
  *)
    init_standalone
    ;;
esac
