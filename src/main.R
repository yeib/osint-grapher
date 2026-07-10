#!/usr/bin/env Rscript
# =============================================================================
# nexusgraph — CLI Entry Point
# =============================================================================
#' Este script actúa como la interfaz de línea de comandos (CLI) principal 
#' para la herramienta NexusGraph, orquestando las funciones 
#' de procesamiento de datos y visualización.

suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(igraph)) # Requerido por vcount(), ecount()

# Determinar la ruta del script para cargar módulos de forma robusta
# Ya sea ejecutando desde ./nexusgraph.sh o directamente con Rscript src/main.R
args_command <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args_command[grep("--file=", args_command)])
if (length(script_path) > 0 && nzchar(script_path[1])) {
  project_root <- dirname(dirname(normalizePath(script_path[1])))
} else {
  project_root <- getwd()
}

# Carga de módulos de la aplicación.
source(file.path(project_root, "R", "process_data.R"))
source(file.path(project_root, "R", "visualize.R"))

# 1. Definición de Parámetros por Consola (CLI)
# -----------------------------------------------------------------------------
option_list <- list(
  make_option(c("-i", "--input"), type = "character", default = NULL,
              help = "Ruta al dataset de entrada (CSV o Excel). Obligatorio.", metavar = "FILE"),
  make_option(c("-o", "--output"), type = "character", default = "output/reporte.html",
              help = "Ruta del archivo HTML interactivo generado. [default: %default]", metavar = "FILE"),
  make_option(c("-s", "--static"), type = "character", default = NULL,
              help = "Ruta para exportar un grafo estático (PNG, JPEG, PDF). Opcional.", metavar = "FILE"),
  make_option(c("--sheet"), type = "character", default = "1",
              help = "Nombre o índice de la hoja (solo si la entrada es Excel). [default: %default]"),
  make_option(c("--min-peso"), type = "numeric", default = 0,
              help = "Peso mínimo para incluir la relación en el grafo. [default: %default]"),
  make_option(c("--tipo"), type = "character", default = NULL,
              help = "Filtro por Tipo_Relacion. Puedes pasar varios tipos separados por comas. [default: Todos]"),
  make_option(c("--undirected"), action = "store_true", default = FALSE,
              help = "Tratar el grafo como no dirigido (conexiones bidireccionales). [default: FALSE]")
)

opt_parser <- OptionParser(
  usage = "Uso: ./nexusgraph.sh [opciones]",
  option_list = option_list,
  description = "Analizador OSINT de Redes y Grafos de Relación."
)

opt <- parse_args(opt_parser)

# 2. Validación de Argumentos
# -----------------------------------------------------------------------------
if (is.null(opt$input)) {
  print_help(opt_parser)
  stop("[Error] El archivo de entrada (-i/--input) es obligatorio.", call. = FALSE)
}

# 3. Flujo Principal envuelto en tryCatch
# -----------------------------------------------------------------------------
tryCatch({
  cat("==================================================\n")
  cat("      🚀 Iniciando NexusGraph Analyzer \n")
  cat("==================================================\n\n")
  
  # Parsear lista de tipos si fue provista
  tipos_filtro <- NULL
  if (!is.null(opt$tipo)) {
    tipos_filtro <- trimws(unlist(strsplit(opt$tipo, ",")))
  }
  
  # --- Paso 1: Lectura y Limpieza ---
  cat("[1/4] Leyendo y validando datos crudos...\n")
  cat(sprintf("      -> Origen: %s \n", opt$input))
  
  df_clean <- load_and_clean_data(
    file_path = opt$input, 
    sheet = opt$sheet, 
    min_peso = opt$`min-peso`, 
    tipos = tipos_filtro
  )
  cat(sprintf("      -> Listo. Encontradas %d relaciones válidas (tras limpieza y filtros).\n\n", nrow(df_clean)))
  
  # --- Paso 2: Generación del Grafo ---
  cat("[2/4] Construyendo el modelo matemático de red...\n")
  
  # Si el usuario pasó --undirected, directed será FALSE. Por defecto es TRUE.
  g <- generate_graph(df_clean, directed = !opt$undirected)
  cat(sprintf("      -> Listo. Red compuesta por %d entidades (nodos) y %d conexiones (aristas).\n\n", 
              vcount(g), ecount(g)))
  
  # --- Paso 3: Análisis de Red (Centralidad y Comunidades) ---
  cat("[3/4] Calculando métricas de centralidad y comunidades...\n")
  g <- compute_network_metrics(g)
  cat("      -> Listo. Nodos coloreados por comunidad automáticamente.\n\n")
  
  print_top_nodes(g)
  
  # --- Paso 4: Visualización ---
  cat("[4/4] Renderizando salidas gráficas...\n")
  
  generate_interactive_html(g, opt$output)
  
  if (!is.null(opt$static)) {
    generate_static_report(g, opt$static)
  }
  
  cat("\n==================================================\n")
  cat(" 🎉 ¡Proceso completado con éxito! \n")
  cat("==================================================\n")
  
}, error = function(e) {
  # tryCatch maneja la excepción, limpia el output y finaliza con error.
  cat("\n==================================================\n")
  cat(" ❌ Ejecución fallida \n")
  cat("==================================================\n")
  cat(e$message, "\n")
  quit(status = 1)
})
