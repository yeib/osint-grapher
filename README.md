# 📊 NexusGraph (R Data Visualizer)

[![CI](https://github.com/yeib/osint-grapher/actions/workflows/ci.yml/badge.svg)](https://github.com/yeib/osint-grapher/actions/workflows/ci.yml)

Bienvenido al proyecto de visualización de datos e inteligencia (OSINT).
Este proyecto está escrito en **R** y se encarga de tomar archivos de datos en bruto (.csv o .xlsx) y transformarlos en gráficos de red interactivos y reportes visuales de alta calidad.

## 📁 Estructura
- `/src`: Scripts principales de R.
- `/data`: Archivos de datos de entrada (`.csv` o `.xlsx`).
- `/output`: Los reportes generados (ignorados por git, se crean al correr el programa).

## 🚀 Uso

### 1. Instalación de Dependencias del Sistema

NexusGraph requiere **R** y **pandoc** instalados en el sistema:

```bash
# En Ubuntu/Debian
sudo apt-get install -y r-base pandoc

# En macOS (con Homebrew)
brew install r pandoc
```

Luego, instala las librerías de R necesarias:

```bash
Rscript install_packages.R
```

### 2. Ejecución

Puedes ejecutar NexusGraph a través del script principal de Bash:

```bash
./nexusgraph.sh -i data/sample.csv -o output/reporte.html -s output/estatico.png
```

### 3. Formato del archivo de entrada

El archivo CSV o Excel debe contener al menos las columnas `Origen` y `Destino`. Las demás son opcionales:

| Columna | Requerida | Descripción |
|---|---|---|
| `Origen` | ✅ | Entidad de origen de la relación |
| `Destino` | ✅ | Entidad de destino de la relación |
| `Tipo_Relacion` | ❌ | Etiqueta del tipo de vínculo (ej: Empleado, Aliado) |
| `Peso` | ❌ | Intensidad numérica de la relación (por defecto: 1) |

¡Todo listo para analizar datos!
