#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════╗
# ║  Projector — One-Command Installer               ║
# ║  Instala el skill de Software Design para         ║
# ║  Antigravity en tu máquina.                       ║
# ╚══════════════════════════════════════════════════╝
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/projector-ai/projector/main/install.sh | bash
#   ó
#   bash install.sh

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()     { echo -e "${BLUE}[projector]${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
error()   { echo -e "${RED}✗${NC} $1" >&2; }

SKILL_DIR="$HOME/.gemini/antigravity/skills/software-design"
REPO_URL="https://github.com/projector-ai/projector"

echo ""
echo -e "${BOLD}📐 Projector Installer${NC}"
echo -e "   Documento técnico interactivo SDLC"
echo ""

# ── Check prerequisites ──
if ! command -v git &> /dev/null; then
  error "git no está instalado. Instálalo primero."
  exit 1
fi

# ── Clone or update ──
TMP_DIR=$(mktemp -d)
trap "rm -rf ${TMP_DIR}" EXIT

log "Descargando Projector..."
git clone --quiet --depth 1 "${REPO_URL}" "${TMP_DIR}" 2>/dev/null || {
  error "No se pudo clonar ${REPO_URL}"
  error "Verifica tu conexión y que el repositorio exista."
  exit 1
}

# ── Install skill ──
log "Instalando skill en ${CYAN}${SKILL_DIR}${NC}"

mkdir -p "${SKILL_DIR}/templates" "${SKILL_DIR}/scripts" "${SKILL_DIR}/workflows"

cp "${TMP_DIR}/skill/SKILL.md"                          "${SKILL_DIR}/SKILL.md"
cp "${TMP_DIR}/skill/templates/dashboard.html"           "${SKILL_DIR}/templates/dashboard.html"
cp "${TMP_DIR}/skill/scripts/init.sh"                    "${SKILL_DIR}/scripts/init.sh"
chmod +x "${SKILL_DIR}/scripts/init.sh"

# New Markdown-first templates
[ -f "${TMP_DIR}/skill/templates/viewer.html" ]          && cp "${TMP_DIR}/skill/templates/viewer.html"          "${SKILL_DIR}/templates/viewer.html"
[ -f "${TMP_DIR}/skill/templates/technical-design.md" ]  && cp "${TMP_DIR}/skill/templates/technical-design.md"  "${SKILL_DIR}/templates/technical-design.md"
# Legacy HTML template (backwards compat)
[ -f "${TMP_DIR}/skill/templates/technical-design.html" ] && cp "${TMP_DIR}/skill/templates/technical-design.html" "${SKILL_DIR}/templates/technical-design.html"

# Workflow
cp "${TMP_DIR}/skill/workflows/software-design.md"       "${SKILL_DIR}/workflows/software-design.md"

success "Skill instalado"

# ── Install workflow (optional, per-project) ──
if [ -d ".agents" ] || [ -d ".agent" ]; then
  WORKFLOW_DIR=""
  [ -d ".agents/workflows" ] && WORKFLOW_DIR=".agents/workflows"
  [ -d ".agent/workflows" ]  && WORKFLOW_DIR=".agent/workflows"
  
  if [ -n "${WORKFLOW_DIR}" ]; then
    cp "${TMP_DIR}/skill/workflows/software-design.md" "${WORKFLOW_DIR}/software-design.md" 2>/dev/null || true
    success "Workflow copiado a ${WORKFLOW_DIR}/software-design.md"
  fi
fi

# ── Done ──
echo ""
echo -e "${GREEN}${BOLD}✓ Projector instalado correctamente${NC}"
echo ""
echo -e "  ${BOLD}Uso con Antigravity:${NC}"
echo -e "    /software-design           Documento para el proyecto actual"
echo -e "    /software-design hub        Hub multi-proyecto"
echo ""
echo -e "  ${BOLD}Uso desde terminal:${NC}"
echo -e "    bash ${SKILL_DIR}/scripts/init.sh"
echo -e "    bash ${SKILL_DIR}/scripts/init.sh --hub"
echo ""
