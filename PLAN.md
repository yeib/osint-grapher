# 📝 Plan de Implementación: NexusGraph

Este documento detalla la ruta de trabajo para construir nuestro visualizador de datos OSINT utilizando R.

## Fases de Desarrollo

### Fase 1: Arquitectura y Configuración Base (R & Librerías)
1. **Instalación del Entorno:** Configurar `R` en el servidor/local y el gestor de paquetes (`renv` o `install.packages`).
2. **Librerías Clave:** 
   - `dplyr` y `readr`: Para limpieza y manipulación rápida de archivos CSV pesados.
   - `igraph`: Para el cálculo matemático de los nodos y aristas (relaciones).
   - `visNetwork`: Para renderizar los gráficos interactivos en HTML.
3. **Estructura de Datos:** Definir el formato estándar del CSV que NexusGraph aceptará (ej: `Origen`, `Destino`, `Tipo_Relacion`, `Peso`).

### Fase 2: Motor de Procesamiento (El "Cerebro")
1. Leer los archivos generados por Scrapic o cualquier herramienta OSINT.
2. Limpiar datos nulos o relaciones duplicadas.
3. Generar el modelo de grafos utilizando la teoría de redes de `igraph`.

### Fase 3: Renderizado y Exportación (Lo "Bonito")
1. **Visor Interactivo HTML:** Generar un archivo HTML donde el analista pueda hacer zoom, arrastrar nodos y ver conexiones (usando `visNetwork`).
2. **Reportes Estáticos:** Exportación de gráficos clave en alta resolución (PDF/PNG) usando `ggplot2` y `ggraph` para incluir en reportes formales.

### Fase 4: Integración (Opcional)
- Crear un *script* orquestador (bash/python) que permita invocar a NexusGraph directamente desde la terminal pasándole la ruta de un CSV.
  Ejemplo: `Rscript src/main.R --input data/scrapic_results.csv --output output/reporte.html`
