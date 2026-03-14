---
description: Genera un documento técnico HTML interactivo siguiendo el SDLC tradicional. Usa /software-design para iniciar.
---

# /software-design — Workflow

## Requisito Previo
Lee las instrucciones completas del skill antes de ejecutar:
```
view_file ~/.gemini/antigravity/skills/software-design/SKILL.md
```

// turbo-all

## Paso 1: Detectar Modo y Bootstrapping

Determina el modo según el comando del usuario:
- `/software-design` → **Standalone** (crea `.projector/` en el workspace actual)
- `/software-design hub` → **Hub** (crea/usa `~/Projects/<org>/`)

> **IMPORTANTE**: Tú (el agente) ejecutas estos comandos directamente usando `run_command`. El usuario autoriza cada ejecución. NO le digas al usuario que ejecute comandos manualmente.

Ejecuta el script de init con `run_command` (SafeToAutoRun=false para que el usuario apruebe):
```bash
# Standalone
bash ~/.gemini/antigravity/skills/software-design/scripts/init.sh

# Hub (requiere nombre de la org GitHub)
bash ~/.gemini/antigravity/skills/software-design/scripts/init.sh --hub <org-name>
```

## Paso 2: Datos del Proyecto

Pregunta al usuario (vía `notify_user`):
1. **Nombre del proyecto** (se usará para `{{PROJECT_NAME}}`)
2. **Descripción breve** (para `{{PROJECT_DESCRIPTION}}`)

Una vez tengas los datos, ejecuta el comando de creación de proyecto tú mismo:
```bash
# Standalone: los placeholders se reemplazan con replace_file_content
# Hub: ejecuta con run_command (el usuario aprobará)
bash ~/.gemini/antigravity/skills/software-design/scripts/init.sh --hub <org-name> "<nombre>" "<descripción>"
```

## Paso 3: Abrir en Navegador

Abre el documento en el navegador con `run_command`:
```bash
# Ejecuta tú directamente (SafeToAutoRun=true, es seguro)
open <ruta-al-archivo>.html
```
- **Standalone:** `open .projector/technical-design.html`
- **Hub:** `open ~/Projects/<org>/projects/<nombre>/technical-design.html`

## Paso 4: Iterar por las 9 Fases SDLC

Para cada fase (1-9), sigue este ciclo:

### 4.1 Preguntar al usuario
Usa `notify_user` para preguntar qué contenido incluir en la fase actual.

### 4.2 Generar contenido HTML
Genera el contenido como bloques HTML usando las clases del template:
- **Párrafos:** `<div class="doc-block type-text" data-type="text">...</div>`
- **Cards:** `<div class="content-card"><h4>Título</h4><p>Contenido</p></div>`
- **Tablas:** `<table class="styled-table">...</table>`
- **Diagramas Mermaid:** `<div class="diagram-container"><div class="diagram-viewport"><pre class="mermaid">...</pre></div></div>`
- **Código:** `<div class="doc-block type-code"><pre><code>...</code></pre></div>`

### 4.3 Actualizar el HTML
Usa `replace_file_content` para:
1. Reemplazar el placeholder de la fase con el contenido generado
2. Actualizar el badge de la fase (`pending` → `completed`)
3. Actualizar el progress bar

### 4.4 Recargar navegador
Usa `browser_subagent` para recargar y mostrar los cambios.

### 4.5 Confirmar y avanzar
Pregunta al usuario si desea ajustar algo o avanzar a la siguiente fase.

## Paso 5: Revisar Comentarios

Después de cada fase, busca comentarios del usuario:
```bash
grep "comments-data" .projector/technical-design.html
```
Si hay comentarios nuevos en el JSON, léelos y responde/actúa según su contenido.

## Paso 6: Finalización

Al completar todas las fases:
1. Actualiza el estado general a "Completado"
2. Genera el Resumen Ejecutivo (fase 9) con un overview de todo
3. Si es modo hub, actualiza la tarjeta en el dashboard
4. Notifica al usuario que el documento está completo

## Referencia: IDs de Secciones

| Fase | Section ID | Content ID | Badge ID |
|------|-----------|------------|----------|
| 1 Planteamiento | `problem-statement` | `problem-statement-content` | `phase-badge-1` |
| 2 Requerimientos | `requirements` | `requirements-content` | `phase-badge-2` |
| 3 Análisis | `analysis` | `analysis-content` | `phase-badge-3` |
| 4 Diseño Sistema | `system-design` | `system-design-content` | `phase-badge-4` |
| 5 Diseño Detallado | `detailed-design` | `detailed-design-content` | `phase-badge-5` |
| 6 Implementación | `implementation-plan` | `implementation-plan-content` | `phase-badge-6` |
| 7 Testing | `testing-strategy` | `testing-strategy-content` | `phase-badge-7` |
| 8 Despliegue | `deployment-operations` | `deployment-operations-content` | `phase-badge-8` |
| 9 Resumen | `executive-summary` | `executive-summary-content` | `phase-badge-9` |
