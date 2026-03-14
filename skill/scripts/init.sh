#!/usr/bin/env bash
# Projector — Init Script
# Usage:
#   bash init.sh              → Standalone mode (creates .projector/ in current directory)
#   bash init.sh --hub        → Hub mode (creates ~/projector-hub/ with dashboard)
#   bash init.sh --hub <dir>  → Hub mode in custom directory

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATES_DIR="${SKILL_DIR}/templates"
DATE=$(date '+%Y-%m-%d')

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${BLUE}[projector]${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }

# ── Hub Mode ──
init_hub() {
  local HUB_DIR="${1:-$HOME/projector-hub}"
  
  log "Inicializando Projector Hub en ${CYAN}${HUB_DIR}${NC}"
  
  mkdir -p "${HUB_DIR}/projects"
  
  if [ ! -f "${HUB_DIR}/index.html" ]; then
    cp "${TEMPLATES_DIR}/dashboard.html" "${HUB_DIR}/index.html"
    success "Dashboard creado: ${HUB_DIR}/index.html"
  else
    log "Dashboard ya existe, no se sobreescribe"
  fi
  
  success "Hub listo en: ${HUB_DIR}"
  echo ""
  echo -e "  Abre el dashboard:  ${CYAN}open ${HUB_DIR}/index.html${NC}"
  echo -e "  Crear proyecto:     ${CYAN}/software-design hub${NC}"
  echo ""
}

# ── Hub: Create Project ──
create_hub_project() {
  local HUB_DIR="${1:-$HOME/projector-hub}"
  local PROJECT_NAME="$2"
  local PROJECT_DESC="${3:-}"
  local PROJECT_DIR="${HUB_DIR}/projects/${PROJECT_NAME}"
  
  log "Creando proyecto '${PROJECT_NAME}' en hub"
  
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
  else
    log "El proyecto '${PROJECT_NAME}' ya existe"
  fi
  
  echo ""
  echo -e "  Abrir documento:  ${CYAN}open ${PROJECT_DIR}/technical-design.html${NC}"
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
  else
    log "Documento técnico ya existe, no se sobreescribe"
  fi
  
  success "Projector listo en: ${TARGET_DIR}"
  echo ""
  echo -e "  Abrir documento:  ${CYAN}open ${TARGET_DIR}/technical-design.html${NC}"
  echo -e "  Iniciar flujo:    ${CYAN}/software-design${NC}"
  echo ""
}

# ── Main ──
case "${1:-}" in
  --hub)
    if [ -n "${3:-}" ]; then
      create_hub_project "${2:-$HOME/projector-hub}" "$3" "${4:-}"
    else
      init_hub "${2:-}"
    fi
    ;;
  --help|-h)
    echo "Projector — Documento Técnico SDLC"
    echo ""
    echo "Uso:"
    echo "  bash init.sh               Standalone (crea .projector/ aquí)"
    echo "  bash init.sh --hub         Hub (crea ~/projector-hub/)"
    echo "  bash init.sh --hub <dir>   Hub en directorio específico"
    echo ""
    ;;
  *)
    init_standalone
    ;;
esac
