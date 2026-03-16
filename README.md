# 📐 Projector

**Visor Markdown interactivo para documentos técnicos de software.**  
Genera y gestiona documentos SDLC de 9 fases — renderiza Markdown + Mermaid en el navegador con live-reload, comentarios y temas.

<p align="center">
  <img src="https://img.shields.io/badge/Antigravity-Skill-6c5ce7?style=for-the-badge" alt="Antigravity Skill">
  <img src="https://img.shields.io/badge/SDLC-9_Fases-00b894?style=for-the-badge" alt="9 Fases SDLC">
  <img src="https://img.shields.io/badge/Markdown-Source_of_Truth-0d1117?style=for-the-badge" alt="Markdown">
  <img src="https://img.shields.io/badge/Mermaid-Diagrams-ff6b6b?style=for-the-badge" alt="Mermaid">
</p>

---

## 🚀 Instalación

```bash
curl -fsSL https://raw.githubusercontent.com/projector-ai/projector/main/install.sh | bash
```

Instala el skill en `~/.gemini/antigravity/skills/software-design/`.

<details>
<summary>Instalación manual</summary>

```bash
git clone https://github.com/projector-ai/projector.git
cd projector && bash install.sh
```
</details>

---

## ⚡ Uso rápido

### Con Antigravity (agente)
```
/software-design              → Documento para el proyecto actual
/software-design hub          → Hub centralizado (multi-proyecto)
```

### Con terminal
```bash
INIT="bash ~/.gemini/antigravity/skills/software-design/scripts/init.sh"

# Standalone: crea .projector/ en el directorio actual
$INIT --standalone

# Hub: crea hub para una organización GitHub
$INIT --hub mi-org

# Crear proyecto dentro del hub
$INIT --hub mi-org mi-api "API de autenticación"

# Escanear directorio existente con repos
$INIT --scan ~/Projects/clusterflux

# Vincular un repo individual a un hub existente
$INIT --link mi-org ~/Projects/mi-repo "Mi proyecto"

# Regenerar content.js después de editar el .md
$INIT --sync ~/Projects/mi-org/projects/mi-api/technical-design.md
```

---

## 🏗️ Arquitectura

```
.md es la fuente de verdad → viewer.html lo renderiza en el browser
```

### Archivos por proyecto

```
proyecto/
├── .projector/
│   ├── technical-design.md   ← Fuente de verdad (Markdown)
│   ├── content.js            ← Generado automáticamente desde el .md
│   └── index.html            ← Visor (marked.js + mermaid.js)
```

- **`technical-design.md`** — se pushea a GitHub/GitLab, se renderiza nativamente allí también
- **`content.js`** — puente para CORS (carga el .md como JS template literal)
- **`index.html`** — visor universal que renderiza Markdown + Mermaid

---

## 🏢 Modos de Uso

### Standalone (un proyecto)
```bash
$INIT --standalone
```
Crea `.projector/` dentro de tu proyecto actual.

### Hub — Organización GitHub
```bash
$INIT --hub condolab-app                          # Crea hub
$INIT --hub condolab-app condo-system "Sistema"   # Agrega proyecto
```

```
~/Projects/condolab-app/
├── index.html                   ← Dashboard
├── metadata.js                  ← Datos de proyectos
└── projects/
    └── condo-system/
        ├── technical-design.md
        ├── content.js
        └── index.html
```

### Scan — Directorio local con repos existentes
```bash
$INIT --scan ~/Projects/clusterflux
```

Escanea subdirectorios con `.git` y crea `.projector/` dentro de cada uno:

```
~/Projects/clusterflux/
├── index.html                   ← Dashboard (generado)
├── metadata.js
├── projects/                    ← Symlinks
│   ├── vloft-api → ../vloft-api/.projector
│   ├── vloft-core → ../vloft-core/.projector
│   └── vloft-ui → ../vloft-ui/.projector
├── vloft-api/
│   ├── src/
│   └── .projector/              ← Documentos técnicos
│       ├── technical-design.md
│       ├── content.js
│       └── index.html
├── vloft-core/
└── vloft-ui/
```

---

## 🖥️ Visor en el navegador

Para visualizar los documentos con live-reload:

```bash
# Levantar servidor local
python3 -m http.server 8765 --directory ~/Projects/clusterflux

# Abrir dashboard
open http://localhost:8765

# Abrir proyecto específico
open http://localhost:8765/projects/vloft-api/index.html
```

### Funcionalidades del visor

| Feature | Detalle |
|---------|---------|
| 📝 **Markdown** | Renderizado con marked.js (GFM, tablas, blockquotes) |
| 📊 **Mermaid** | Diagramas: flujo, secuencia, ER, Gantt, arquitectura |
| ⛶ **Fullscreen** | Hover sobre diagrama → botón de pantalla completa |
| 💬 **Comentarios** | Selecciona texto → clic derecho → agregar comentario |
| 🔴 **Live reload** | Auto-actualiza cada 2s cuando el agente edita el .md |
| 🎨 **3 Temas** | ☀️ Claro · 🌙 Oscuro · 🌿 Suave |
| 📌 **Sidebar** | Navegación auto-generada desde headings H2 |
| 📈 **Progreso** | Tracking de fases completadas via marcadores `PHASE` |

---

## 📄 Fases del Documento SDLC

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

## 🔄 Flujo de trabajo con Antigravity

```mermaid
graph LR
    A[/software-design] --> B[Agente edita .md]
    B --> C[Visor detecta cambio]
    C --> D[Re-renderiza Markdown + Mermaid]
    D --> E[Usuario revisa en browser]
    E --> F{¿Ajustar?}
    F -->|Sí| G[Comentario o instrucción]
    G --> B
    F -->|No| H[Siguiente fase]
    H --> B
```

1. El usuario ejecuta `/software-design`
2. El agente edita `technical-design.md` fase por fase
3. El visor se actualiza automáticamente (live-reload)
4. El usuario comenta o aprueba desde el browser
5. Al completar las 9 fases, el `.md` se pushea al repo

---

## 📁 Estructura del Repositorio

```
projector/
├── README.md
├── install.sh                   ← Instalador
├── .env.example                 ← Variables de entorno
└── skill/
    ├── SKILL.md                 ← Instrucciones para el agente
    ├── templates/
    │   ├── technical-design.md  ← Template Markdown (9 fases SDLC)
    │   ├── viewer.html          ← Visor (marked.js + mermaid.js)
    │   └── dashboard.html       ← Dashboard (hub mode)
    ├── scripts/
    │   └── init.sh              ← Bootstrapping + sync + scan
    └── workflows/
        └── software-design.md   ← Workflow de Antigravity
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
