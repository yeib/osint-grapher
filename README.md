# 📊 NexusGraph

[![CI](https://github.com/yeib/osint-grapher/actions/workflows/ci.yml/badge.svg)](https://github.com/yeib/osint-grapher/actions/workflows/ci.yml)
[![R](https://img.shields.io/badge/R-%3E%3D4.1-blue)](https://www.r-project.org/)
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker)](https://www.docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

Herramienta de código abierto escrita en **R** para transformar archivos de datos tabulares (CSV o Excel) en **grafos interactivos de red**, con análisis automático de centralidad y detección de comunidades. Ideal para OSINT, análisis de redes sociales y visualización de relaciones entre entidades.

## 📁 Estructura

```
nexusgraph/
├── src/
│   ├── main.R           # Orquestador CLI
│   ├── process_data.R   # Lectura, limpieza y métricas de red
│   ├── visualize.R      # Exportación HTML interactivo y PNG
│   └── app.R            # Interfaz web local (Shiny)
├── data/                # Archivos de entrada (.csv / .xlsx)
├── output/              # Reportes generados (ignorados por git)
├── tests/               # Suite de tests unitarios (55 tests)
└── nexusgraph.sh        # Wrapper principal de ejecución
```

## 🚀 Instalación

### Opción A — Docker (recomendado, sin instalar R)

```bash
# Construir la imagen
docker build -t nexusgraph .

# Modo CLI: analizar un archivo local
docker run --rm \
  -v $(pwd)/data:/nexusgraph/data \
  -v $(pwd)/output:/nexusgraph/output \
  nexusgraph -i data/mi_archivo.csv

# Modo Web UI: abrir en http://localhost:3838
docker run --rm -p 3838:3838 nexusgraph --web
```

### Opción B — Instalación local con R

NexusGraph requiere **R (≥ 4.1)** y **pandoc**:

```bash
# Ubuntu/Debian
sudo apt-get install -y r-base pandoc

# macOS (Homebrew)
brew install r pandoc
```

### 2. Dependencias de R

```bash
Rscript install_packages.R
```

## 🖥️ Uso — Modo CLI

```bash
./nexusgraph.sh -i data/marvel_sample.csv -o output/reporte.html
```

### Opciones disponibles

| Opción | Descripción | Default |
|--------|-------------|---------|
| `-i, --input` | Ruta al archivo CSV o Excel de entrada **(Requerido)** | — |
| `-o, --output` | Ruta para el reporte HTML interactivo | `output/reporte.html` |
| `-s, --static` | Ruta para imagen estática (PNG/PDF). Si se omite, no se genera | — |
| `--sheet` | Nombre o número de hoja Excel a leer | `1` |
| `--min-peso` | Ignorar relaciones con Peso menor a este valor | `0` |
| `--tipo` | Filtrar por tipos de relación (separados por coma) | todos |
| `--undirected` | Generar grafo no dirigido (relaciones bidireccionales) | dirigido |

### Ejemplos

```bash
# Básico
./nexusgraph.sh -i data/mi_dataset.csv

# Excel con hoja específica + filtros
./nexusgraph.sh -i data/reporte.xlsx --sheet "Empleados" --min-peso 3 --tipo "Contrato,Proveedor"

# Grafo no dirigido con imagen estática
./nexusgraph.sh -i data/red.csv --undirected -s output/red.png
```

## 🌐 Uso — Interfaz Web Local

Para usuarios que prefieren una interfaz gráfica en el navegador:

```bash
./nexusgraph.sh --web
```

Abre tu navegador en `http://localhost:3838`. Desde ahí puedes:
- **Arrastrar y soltar** tu CSV o Excel
- Aplicar filtros en tiempo real
- Ver el grafo interactivo con comunidades coloreadas
- Descargar el reporte HTML o la imagen PNG

## 📋 Formato del Archivo de Entrada

El archivo debe contener al menos las columnas `Origen` y `Destino`:

| Columna | Requerida | Descripción |
|---------|-----------|-------------|
| `Origen` | ✅ | Entidad de origen de la relación |
| `Destino` | ✅ | Entidad de destino de la relación |
| `Tipo_Relacion` | ❌ | Tipo de vínculo (ej: Empleado, Aliado). Default: `Desconocido` |
| `Peso` | ❌ | Intensidad numérica de la relación. Default: `1` |

### Ejemplo

```csv
Origen,Destino,Tipo_Relacion,Peso
Alice,Bob,Colega,3
Bob,Carol,Familiar,5
Carol,Alice,Amigo,2
```

## 🧠 Qué Analiza NexusGraph

Al procesar cualquier dataset, la herramienta calcula automáticamente:

- **Degree Centrality**: Quién tiene más conexiones (el "hub" de la red)
- **Betweenness Centrality**: Quién actúa como "puente" entre grupos
- **Detección de Comunidades** (Louvain): Grupos de entidades naturalmente relacionadas, coloreados automáticamente en el grafo
- **Top 5 Entidades** más importantes, impresas en consola al finalizar

## 🧪 Tests

```bash
Rscript tests/run_tests.R
# [ FAIL 0 | WARN 0 | SKIP 0 | PASS 55 ]
```
