# NexusGraph — Changelog

Todas los cambios relevantes del proyecto se documentan en este archivo.
Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).

---

## [0.2.0] — 2026-07-06

### ✨ Nuevas Features
- **Análisis de red automático**: Detección de comunidades con algoritmo Louvain, centralidad de grado (degree) y de intermediación (betweenness) calculadas en cada ejecución.
- **Top 5 hubs en consola**: Al terminar, imprime en pantalla las entidades más importantes de la red con sus métricas.
- **Coloreado automático por comunidades**: Nodos en el HTML interactivo y PNG estático coloreados por grupo detectado automáticamente.
- **Interfaz Web Local (`--web`)**: Nueva app Shiny con panel de control, pantalla de bienvenida, contador de nodos/aristas, y notificaciones de error amigables.
  - Lanzar con: `./nexusgraph.sh --web` (o `--web --port=4000`)
- **Filtros en CLI**:
  - `--min-peso N`: Ignorar relaciones con peso menor a N.
  - `--tipo "A,B"`: Filtrar por tipos de relación específicos.
  - `--undirected`: Generar grafo no dirigido (bidireccional).
  - `--sheet "Nombre"`: Elegir hoja de Excel por nombre o número.
- **Docker**: `Dockerfile` y `.dockerignore` para distribución sin fricción.
- **Suite de tests**: 55 tests unitarios con `testthat` (3 suites).
- **CI/CD**: GitHub Actions con caché de paquetes R.

### 🐛 Bugs Corregidos
- `withCallingHandlers` reemplazado por `tryCatch` en `main.R` (el handler anterior re-lanzaba el error original produciendo stack traces crudos).
- Crash de `cluster_louvain` con grafos de 1 solo nodo.
- Descarga de PNG en Shiny fallaba silenciosamente (Shiny pasa path sin extensión).
- Posible XSS en tooltips de visNetwork si el CSV contenía HTML; ahora se usa `htmltools::htmlEscape()`.
- Strings con espacios al inicio/fin en Origen/Destino creaban entidades fantasma; ahora se aplica `trimws()`.
- `print_top_nodes` crasheaba si se llamaba sin haber ejecutado `compute_network_metrics`.
- `for(i in 1:0)` reemplazado por `seq_len()` para evitar iteraciones inválidas.
- `row_heights` no es argumento válido de `layout_columns` en bslib (eliminado).
- Numeración de steps en CI/CD desfasada (cosmético).

### 🏗️ Infraestructura
- `DESCRIPTION` formaliza el proyecto como paquete R.
- `install_packages.R`: añadido `dependencies = TRUE` y verificación post-instalación.
- `nexusgraph.sh`: parseo correcto de `--web` en cualquier posición, `--port` configurable.
- README completamente reescrito con todas las opciones documentadas.

---

## [0.1.0] — 2026-07-05

### ✨ Release Inicial
- CLI funcional: `./nexusgraph.sh -i data.csv -o output/reporte.html`
- Lectura de CSV y Excel (`.xlsx`).
- Grafo dirigido interactivo (HTML) con `visNetwork`.
- Reporte estático de alta resolución (PNG/PDF) con `ggraph`.
- Código modularizado en `src/`: `main.R`, `process_data.R`, `visualize.R`.
- Validación de columnas requeridas (`Origen`, `Destino`).
- Normalización de columnas opcionales (`Tipo_Relacion`, `Peso`).
- Datos de muestra: `data/marvel_sample.csv`, `data/sample.csv`.
