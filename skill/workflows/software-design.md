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

## Paso 1: Inicialización Completa (ejecutar todo sin pausas)

> **IMPORTANTE**: Tú (el agente) ejecutas TODOS estos comandos directamente usando `run_command`. El usuario autoriza cada ejecución. NO le digas al usuario que ejecute comandos manualmente. Después de crear el proyecto, continúa AUTOMÁTICAMENTE con la Fase 1.

### 1.1 Detectar Modo
Determina el modo según el comando del usuario:
- `/software-design` → **Standalone** (crea `.projector/` en el workspace actual)
- `/software-design hub` → **Hub** (crea/usa `~/Projects/<org>/`)

### 1.2 Preguntar Datos del Proyecto
Usa `notify_user` para preguntar:
1. **Nombre de la organización** (solo en modo hub)
2. **Nombre del proyecto**
3. **Descripción breve del proyecto** — pide que sea detallada, es el contexto que usarás para las fases

### 1.3 Crear el Proyecto
Ejecuta con `run_command` (SafeToAutoRun=false):
```bash
# Standalone
bash ~/.gemini/antigravity/skills/software-design/scripts/init.sh --standalone

# Hub
bash ~/.gemini/antigravity/skills/software-design/scripts/init.sh --hub <org-name> "<nombre>" "<descripción>"
```

### 1.4 Confirmar creación y arrancar
Después de que el script confirme la creación:
1. Localiza el archivo `technical-design.md` generado
2. **NO te detengas** — continúa directamente al Paso 2 (Fase 1 del SDLC)

## Paso 2: Fase 1 — Planteamiento del Problema (iniciar automáticamente)

> **⚡ ARRANQUE AUTOMÁTICO**: Después de crear el proyecto, comienza esta fase sin esperar. Usa la descripción del proyecto como contexto para generar el contenido inicial.

1. Lee la descripción proporcionada por el usuario en el paso anterior
2. Genera el contenido de la Fase 1 directamente en `technical-design.md`
3. Usa `replace_file_content` para reemplazar la sección `<!-- PHASE:problem-statement:STATUS:pending -->`
4. Marca como completada: `STATUS:pending` → `STATUS:completed`
5. Notifica al usuario con `notify_user` mostrando lo que generaste y preguntando si desea ajustes o avanzar

## Paso 3: Iterar Fases 2-9 del SDLC

Para cada fase restante (2-9), sigue este ciclo:

### 3.1 Preguntar al usuario
Usa `notify_user` para preguntar qué contenido incluir en la fase actual.

### 3.2 Generar contenido
> **IMPORTANTE**: Genera el contenido en **Markdown** y edita el archivo `technical-design.md`. Este es el archivo **fuente de verdad** y se renderiza en GitHub.

Usa formato estándar Markdown:
- **Texto**: Párrafos, listas, citas
- **Tablas**: Markdown tables (`| Col1 | Col2 |`)
- **Diagramas**: Bloques Mermaid (` ```mermaid ... ``` `) — GitHub los renderiza nativamente
- **Código**: Bloques fenced (` ```lang ... ``` `)

### 3.3 Actualizar el Markdown
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

### 3.4 Sincronizar visor
Después de cada edición al `.md`, regenera `content.js` para que el visor refleje los cambios:
```bash
# Ejecuta con run_command (SafeToAutoRun=true, es seguro)
bash ~/.gemini/antigravity/skills/software-design/scripts/init.sh --sync <ruta-al-technical-design.md>
```
> O si tienes python3 disponible, puedes generar content.js directamente inline.

### 3.5 Confirmar y avanzar
Pregunta al usuario si desea ajustar algo o avanzar a la siguiente fase.

## Paso 4: Finalización

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
