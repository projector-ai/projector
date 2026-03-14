---
name: software-design
description: Genera documentos técnicos interactivos siguiendo el SDLC tradicional. Soporta modo standalone (por proyecto) y modo hub (multi-proyecto como GitHub). Usa /software-design para iniciar.
---

# Software Design — Projector

Skill para generar documentos técnicos interactivos con las 9 fases del SDLC. El documento se visualiza en el navegador con edición inline, bloques tipo Jupyter, comentarios para el agente, diagramas Mermaid, y 3 temas visuales.

## When to use this skill
- Cuando el usuario invoca `/software-design`
- Cuando se necesita crear un documento técnico para un proyecto
- Cuando se quiere gestionar múltiples diseños de software centralizados

## Dos Modos de Uso

### Modo Standalone (por proyecto)
```
/software-design
```
Crea `.projector/technical-design.html` dentro del workspace actual. Ideal cuando trabajas en un solo proyecto.

### Modo Hub (multi-proyecto)
```
/software-design hub
```
Crea o abre un hub centralizado en `~/projector-hub/` con un dashboard tipo GitHub para gestionar múltiples proyectos de diseño.

## How to use it

### Paso 1: Bootstrapping
Al recibir el comando, verifica si la estructura existe. Si no:

**Standalone:**
```bash
# Ejecutar el init script del skill
bash ~/.gemini/antigravity/skills/software-design/scripts/init.sh
```

**Hub:**
```bash
bash ~/.gemini/antigravity/skills/software-design/scripts/init.sh --hub
```

### Paso 2: Personalización del Documento
1. Pregunta al usuario nombre y descripción del proyecto
2. Copia el template desde `~/.gemini/antigravity/skills/software-design/templates/technical-design.html`
3. Reemplaza los placeholders: `{{PROJECT_NAME}}`, `{{PROJECT_DESCRIPTION}}`, `{{DATE}}`
4. Si es modo hub, también actualiza `index.html` para agregar la tarjeta del proyecto

### Paso 3: Abrir en Navegador
Abre el documento con `browser_subagent` o indica al usuario que abra el archivo.

### Paso 4: Iteración por Fases (9 fases SDLC)
Guía al usuario fase por fase:

1. **Planteamiento del Problema** — Define el problema a resolver
2. **Requerimientos** — Funcionales, no funcionales, restricciones
3. **Análisis** — Casos de uso, actores, reglas de negocio
4. **Diseño del Sistema** — Arquitectura, componentes, diagramas
5. **Diseño Detallado** — Modelos de datos, APIs, interfaces
6. **Plan de Implementación** — Sprints, tareas, prioridades
7. **Estrategia de Testing** — Unitarios, integración, E2E
8. **Despliegue y Operaciones** — CI/CD, infraestructura, monitoreo
9. **Resumen Ejecutivo** — Síntesis del diseño completo

Para cada fase:
1. Pregunta al usuario qué incluir vía `notify_user`
2. Genera el contenido HTML para esa sección
3. Actualiza el archivo `technical-design.html` con `replace_file_content` o `multi_replace_file_content`
4. Actualiza el badge de la fase a "Completada" y el progress bar
5. Recarga el navegador con `browser_subagent`

### Paso 5: Comentarios del Usuario
El usuario puede agregar comentarios desde el navegador (clic derecho → "Comentario para Agente"). Los comentarios se guardan en un JSON embebido (`#comments-data`) dentro del HTML. Para leerlos:

```javascript
// El bloque está al final del HTML
<script type="application/json" id="comments-data">[...]</script>
```

Lee este bloque con `grep_search` buscando `comments-data` y procesa el JSON para responder/actuar sobre los comentarios.

## Estructura de Archivos del Skill

```
~/.gemini/antigravity/skills/software-design/
├── SKILL.md                            ← Este archivo
├── templates/
│   ├── technical-design.html           ← Template del documento técnico
│   └── dashboard.html                  ← Template del dashboard (modo hub)
└── scripts/
    └── init.sh                         ← Script de bootstrapping
```

## Estructura Generada

**Standalone:**
```
<workspace>/
└── .projector/
    └── technical-design.html
```

**Hub:**
```
~/projector-hub/
├── index.html                          ← Dashboard
└── projects/
    └── <nombre>/
        └── technical-design.html
```

## Características del Documento
- 🎨 3 temas: Claro, Oscuro, Suave (toggle en esquina inferior derecha)
- ➕ Bloques tipo Jupyter (Texto, Texto IA, Diagrama, Tabla, Código)
- ✏️ Edición inline (doble clic)
- 📋 Menú contextual (clic derecho → Editar, Copiar, Comentario, Solicitar Cambio, Eliminar)
- 🔍 Zoom global + zoom por diagrama
- 💬 Panel de comentarios con persistencia JSON
- 📊 Diagramas Mermaid (flujo, secuencia, ER, Gantt)

## Constraints
- Los templates siempre se leen desde el directorio del skill, nunca se modifican in-place
- Los archivos generados son las copias de trabajo
- Los comentarios del usuario se persisten dentro del HTML mismo
