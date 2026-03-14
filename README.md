# 📐 Projector

**Documento técnico interactivo para diseño de software.**  
Genera y gestiona documentos que siguen las 9 fases del SDLC, directo en tu navegador.

<p align="center">
  <img src="https://img.shields.io/badge/Antigravity-Skill-6c5ce7?style=for-the-badge" alt="Antigravity Skill">
  <img src="https://img.shields.io/badge/SDLC-9_Fases-00b894?style=for-the-badge" alt="9 Fases SDLC">
  <img src="https://img.shields.io/badge/Temas-3-ffa726?style=for-the-badge" alt="3 Temas">
</p>

---

## 🚀 Instalación (un comando)

```bash
curl -fsSL https://raw.githubusercontent.com/projector-ai/projector/main/install.sh | bash
```

Esto instala el skill de Projector en tu directorio de Antigravity (`~/.gemini/antigravity/skills/software-design/`).

### Instalación manual
```bash
git clone https://github.com/projector-ai/projector.git
cd projector
bash install.sh
```

---

## ⚡ Uso

### Con Antigravity
```
/software-design              → Documento para el proyecto actual
/software-design hub           → Hub centralizado (multi-proyecto)
```

### Con terminal
```bash
# Standalone: crea .projector/ en el directorio actual
bash ~/.gemini/antigravity/skills/software-design/scripts/init.sh

# Hub: crea ~/projector-hub/ con dashboard
bash ~/.gemini/antigravity/skills/software-design/scripts/init.sh --hub
```

---

## 🏗️ Modos de Uso

### Standalone (un proyecto)
Crea `.projector/technical-design.html` dentro de tu proyecto.

```
mi-proyecto/
├── src/
├── .projector/
│   └── technical-design.html    ← Tu documento técnico
└── ...
```

### Hub (multi-proyecto, tipo GitHub)
Un dashboard central que gestiona múltiples proyectos de diseño.

```
~/projector-hub/
├── index.html                   ← Dashboard
└── projects/
    ├── app-movil/
    │   └── technical-design.html
    ├── api-gateway/
    │   └── technical-design.html
    └── ...
```

---

## 🏢 Inicializar una Organización

Si tienes múltiples equipos o proyectos, puedes usar Projector como hub centralizado para toda la organización:

### 1. Crear el hub de la organización
```bash
# Crea el hub en un directorio compartido o repositorio
bash ~/.gemini/antigravity/skills/software-design/scripts/init.sh --hub ~/mi-org-hub
```

### 2. Agregar proyectos
```bash
# Cada proyecto se crea como subdirectorio
bash ~/.gemini/antigravity/skills/software-design/scripts/init.sh --hub ~/mi-org-hub "proyecto-alpha" "Sistema de autenticación OAuth2"
bash ~/.gemini/antigravity/skills/software-design/scripts/init.sh --hub ~/mi-org-hub "proyecto-beta" "API Gateway para microservicios"
```

### 3. Abrir el dashboard
```bash
open ~/mi-org-hub/index.html
```

### 4. Flujo de trabajo por proyecto
```
# Desde Antigravity, en cualquier workspace
/software-design hub

# El agente te preguntará nombre y descripción
# y creará el proyecto en el hub
```

### Estructura resultante
```
mi-org-hub/
├── index.html                              ← Dashboard de la organización
└── projects/
    ├── proyecto-alpha/
    │   └── technical-design.html            ← Documento completo
    ├── proyecto-beta/
    │   └── technical-design.html
    └── proyecto-gamma/
        └── technical-design.html
```

> **Tip:** Versiona el hub con Git para mantener el historial de cambios en tus documentos técnicos.

---

## 📄 Fases del Documento

| # | Fase | Descripción |
|---|------|-------------|
| 1 | **Planteamiento del Problema** | Define qué problema se resuelve |
| 2 | **Requerimientos** | Funcionales, no funcionales, restricciones |
| 3 | **Análisis** | Casos de uso, actores, reglas de negocio |
| 4 | **Diseño del Sistema** | Arquitectura, componentes, diagramas |
| 5 | **Diseño Detallado** | Modelos de datos, APIs, interfaces |
| 6 | **Plan de Implementación** | Sprints, tareas, prioridades |
| 7 | **Estrategia de Testing** | Unitarios, integración, E2E |
| 8 | **Despliegue y Operaciones** | CI/CD, infraestructura, monitoreo |
| 9 | **Resumen Ejecutivo** | Síntesis del diseño completo |

---

## ✨ Características

| Feature | Detalle |
|---------|---------|
| 🎨 **3 Temas** | ☀️ Claro · 🌙 Oscuro · 🌿 Suave (eye comfort) |
| ➕ **Bloques Jupyter** | Texto, Texto IA, Diagrama Mermaid, Tabla, Código |
| ✏️ **Edición inline** | Doble clic para editar cualquier bloque |
| 📋 **Menú contextual** | Clic derecho → Editar, Copiar, Comentar, Solicitar Cambio |
| 💬 **Comentarios IA** | Feedback embebido que el agente lee y actúa |
| 🔍 **Zoom** | Global + por diagrama + Ctrl+scroll |
| 📊 **Diagramas** | Mermaid: flujo, secuencia, ER, Gantt, etc. |

---

## 📁 Estructura del Repositorio

```
projector/
├── README.md                    ← Este archivo
├── install.sh                   ← Instalador de un comando
└── skill/
    ├── SKILL.md                 ← Instrucciones para el agente
    ├── templates/
    │   ├── technical-design.html ← Template del documento técnico
    │   └── dashboard.html        ← Template del dashboard (hub)
    ├── scripts/
    │   └── init.sh               ← Script de bootstrapping
    └── workflows/
        └── software-design.md    ← Workflow de Antigravity
```

---

## 🤝 Contribuir

1. Fork el repositorio
2. Crea tu rama (`git checkout -b feature/mi-mejora`)
3. Commit (`git commit -m 'Agrega mi mejora'`)
4. Push (`git push origin feature/mi-mejora`)
5. Abre un Pull Request

---

## 📜 Licencia

MIT © [projector-ai](https://github.com/projector-ai)
