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

### 4.2 Generar contenido
> **IMPORTANTE**: Genera el contenido en **Markdown** y edita el archivo `technical-design.md`. Este es el archivo **fuente de verdad** y se renderiza en GitHub.

Usa formato estándar Markdown:
- **Texto**: Párrafos, listas, citas
- **Tablas**: Markdown tables (`| Col1 | Col2 |`)
- **Diagramas**: Bloques Mermaid (` ```mermaid ... ``` `) — GitHub los renderiza nativamente
- **Código**: Bloques fenced (` ```lang ... ``` `)

### 4.3 Actualizar el Markdown
Usa `replace_file_content` en `technical-design.md` para:
1. Reemplazar el contenido placeholder de la fase (entre marcadores `<!-- PHASE:xxx:STATUS:pending -->`)
2. Cambiar el marcador de estado: `STATUS:pending` → `STATUS:completed`
3. Reemplazar el indicador visual: `> 🔲 **Fase pendiente**` → `> ✅ **Fase completada**`

Ejemplo:
```markdown
<!-- PHASE:problem-statement:STATUS:completed -->

> ✅ **Fase completada**

### Contexto
[Contenido real generado]
```

### 4.4 Confirmar y avanzar
Pregunta al usuario si desea ajustar algo o avanzar a la siguiente fase.

## Paso 5: Finalización

Al completar todas las fases:
1. Actualiza el estado general del marcador de cada fase a `completed`
2. Genera el Resumen Ejecutivo (fase 9) con un overview de todo
3. Si es modo hub, actualiza la metadata del dashboard (fase completada)
4. Notifica al usuario que el documento está completo

## Referencia: Marcadores de Fase (HTML comments en .md)

| Fase | Marcador |
|------|----------|
| 1 Planteamiento | `<!-- PHASE:problem-statement:STATUS:pending -->` |
| 2 Requerimientos | `<!-- PHASE:requirements:STATUS:pending -->` |
| 3 Análisis | `<!-- PHASE:analysis:STATUS:pending -->` |
| 4 Diseño Sistema | `<!-- PHASE:system-design:STATUS:pending -->` |
| 5 Diseño Detallado | `<!-- PHASE:detailed-design:STATUS:pending -->` |
| 6 Implementación | `<!-- PHASE:implementation-plan:STATUS:pending -->` |
| 7 Testing | `<!-- PHASE:testing-strategy:STATUS:pending -->` |
| 8 Despliegue | `<!-- PHASE:deployment-operations:STATUS:pending -->` |
| 9 Resumen | `<!-- PHASE:executive-summary:STATUS:pending -->` |
