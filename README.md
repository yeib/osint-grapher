# 📊 NexusGraph (R Data Visualizer)

Bienvenido al proyecto de visualización de datos e inteligencia (OSINT).
Este proyecto está escrito en **R** y se encarga de tomar archivos de datos en bruto (.csv o .xlsx) y transformarlos en gráficos de red interactivos y reportes visuales de alta calidad.

## 📁 Estructura
- `/src`: Scripts de R (`.R` o Jupyter Notebooks).
- `/data`: Archivos `.csv` de prueba (ej: exportados desde Scrapic).
- `/output`: Los reportes en PDF y archivos HTML generados.

## 🚀 Uso

### 1. Instalación de Dependencias

Asegúrate de tener R instalado en tu sistema. Luego, instala las librerías necesarias ejecutando:

```bash
Rscript install_packages.R
```

### 2. Ejecución

Puedes ejecutar NexusGraph a través del script principal de Bash:

```bash
./nexusgraph.sh -i data/sample.csv -o output/reporte.html -s output/estatico.png
```

¡Todo listo para analizar datos!
