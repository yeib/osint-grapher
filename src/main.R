#' @title Script Principal de Orquestación: NexusGraph
#' @description 
#' Punto de entrada por línea de comandos para NexusGraph.
#' Gestiona el parseo de argumentos y coordina el flujo de los módulos
#' de procesamiento de datos y visualización.

suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(igraph)) # Requerido por vcount(), ecount()

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
              metavar = "Ruta"),
  
  make_option(c("--sheet"), type = "character", default = "1",
              help = "Nombre o número de la hoja de Excel a leer [Por defecto: %default]", 
              metavar = "Hoja"),

  make_option(c("--min-peso"), type = "numeric", default = 0,
              help = "Ignorar relaciones con Peso menor a este valor [Por defecto: %default]", 
              metavar = "Min"),
  
  make_option(c("--tipo"), type = "character", default = NULL,
              help = "Filtrar por tipos de relación específicos, separados por coma (ej: 'Amigo,Enemigo')", 
              metavar = "Tipos"),
  
  make_option(c("--undirected"), action = "store_true", default = FALSE,
              help = "Genera un grafo no dirigido (relaciones bidireccionales)")
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

# tryCatch es el patrón correcto para "capturar el error y terminar el proceso".
# withCallingHandlers propaga el error original después del handler, generando
# un stack trace crudo. tryCatch lo captura sin propagarlo.
tryCatch(
  {
    # Paso A: Lectura y Limpieza
    cat("[1/4] Leyendo y validando datos crudos...\n")
    cat("      -> Origen:", opt$input, "\n")
    
    # Procesar filtros (tipos separados por coma)
    tipos_filtro <- NULL
    if (!is.null(opt$tipo)) {
      tipos_filtro <- trimws(unlist(strsplit(opt$tipo, ",")))
    }

    df <- load_and_clean_data(opt$input, sheet = opt$sheet, min_peso = opt$`min-peso`, tipos = tipos_filtro)
    cat("      -> Listo. Encontradas", nrow(df), "relaciones válidas (tras limpieza y filtros).\n\n")

    # Paso B: Creación del Modelo
    cat("[2/4] Construyendo el modelo matemático de red...\n")
    g <- generate_graph(df, directed = !opt$undirected)
    cat("      -> Listo. Red compuesta por", vcount(g), "entidades (nodos) y", ecount(g), "conexiones (aristas).\n\n")

    # Paso C: Inteligencia y Métricas de Red
    cat("[3/4] Calculando métricas de centralidad y comunidades...\n")
    g <- compute_network_metrics(g)
    cat("      -> Listo. Nodos coloreados por comunidad automáticamente.\n\n")

    # Mostrar top nodos por consola
    print_top_nodes(g)

    # Paso D: Visualización y Exportación
    cat("[4/4] Renderizando salidas gráficas...\n")

    # Interactivo siempre se genera
    generate_interactive_html(g, opt$output)
    
    # Estático solo si el usuario lo solicitó
    if (!is.null(opt$static)) {
      cat("\n      [Opcional] Generando reporte estático...\n")
      generate_static_report(g, opt$static)
    }
    
    cat("\n==================================================\n")
    cat(" 🎉 ¡Proceso completado con éxito! \n")
    cat("==================================================\n")
  },
  error = function(e) {
    cat("\n❌ [Error Fatal]", conditionMessage(e), "\n")
    cat("Abortando NexusGraph. Revisa tu archivo de entrada o los parámetros usados.\n")
    quit(status = 1)
  }
)
