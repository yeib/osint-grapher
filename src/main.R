#' @title Script Principal de Orquestación: NexusGraph
#' @description 
#' Punto de entrada por línea de comandos para NexusGraph.
#' Gestiona el parseo de argumentos y coordina el flujo de los módulos
#' de procesamiento de datos y visualización.

suppressPackageStartupMessages(library(optparse))

# Carga de módulos de la aplicación.
# El wrapper en bash ya se encarga de asegurar que el Working Directory
# sea la raíz del proyecto, así que podemos usar rutas relativas seguras.
source("src/process_data.R")
source("src/visualize.R")

# 1. Definición de Parámetros por Consola (CLI)
# -----------------------------------------------------------------------------
option_list <- list(
  make_option(c("-i", "--input"), type = "character", default = NULL, 
              help = "Ruta al archivo CSV o Excel (.xlsx) de entrada [Requerido]", 
              metavar = "Ruta"),
  
  make_option(c("-o", "--output"), type = "character", default = "output/reporte.html", 
              help = "Ruta donde se guardará el visor interactivo HTML [Por defecto: %default]", 
              metavar = "Ruta"),
  
  make_option(c("-s", "--static"), type = "character", default = NULL,
              help = "Ruta opcional para generar una imagen estática (PNG o PDF). Si se omite, no se genera.", 
              metavar = "Ruta")
)

opt_parser <- OptionParser(
  usage = "Uso: ./nexusgraph.sh -i <entrada.csv> [opciones]",
  option_list = option_list,
  description = "\nNexusGraph: Transformador de archivos CSV a grafos interactivos OSINT."
)

opt <- parse_args(opt_parser)

# 2. Validación Inicial de Argumentos
# -----------------------------------------------------------------------------
if (is.null(opt$input)){
  print_help(opt_parser)
  cat("\n[Error Fatal] Debes proporcionar un archivo de entrada usando --input o -i\n")
  quit(status = 1)
}

# 3. Flujo de Ejecución (Pipeline)
# -----------------------------------------------------------------------------
cat("==================================================\n")
cat("      🚀 Iniciando NexusGraph Analyzer \n")
cat("==================================================\n\n")

# Paso A: Lectura y Limpieza
cat("[1/3] Leyendo y validando datos crudos...\n")
cat("      -> Origen:", opt$input, "\n")
df <- load_and_clean_data(opt$input)
cat("      -> Listo. Encontradas", nrow(df), "relaciones válidas (tras limpieza).\n\n")

# Paso B: Creación del Modelo
cat("[2/3] Construyendo el modelo matemático de red...\n")
g <- generate_graph(df)
cat("      -> Listo. Red compuesta por", vcount(g), "entidades (nodos) y", ecount(g), "conexiones (aristas).\n\n")

# Paso C: Visualización y Exportación
cat("[3/3] Renderizando salidas gráficas...\n")

# Interactivo siempre se genera (a menos que haya un error fatal)
generate_interactive_html(g, opt$output)

# Estático solo se genera si el usuario lo solicitó explícitamente
if (!is.null(opt$static)) {
  cat("\n      [Opcional] Generando reporte estático...\n")
  generate_static_report(g, opt$static)
}

cat("\n==================================================\n")
cat(" 🎉 ¡Proceso completado con éxito! \n")
cat("==================================================\n")
