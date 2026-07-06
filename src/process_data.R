#' @title Procesamiento de Datos para NexusGraph
#' @description 
#' Este módulo se encarga de la lectura, limpieza y transformación
#' de los datos crudos (CSV) en modelos de grafos utilizando igraph.
#' Al ser un proyecto público, el diseño busca ser robusto y tolerante a fallos.

suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(readxl))
suppressPackageStartupMessages(library(igraph))

#' @name load_and_clean_data
#' @description Lee un archivo CSV y limpia los datos, eliminando valores nulos y relaciones duplicadas.
#' @param file_path Ruta al archivo CSV.
#' @return Un dataframe limpio con las columnas Origen, Destino, Tipo_Relacion y Peso.
load_and_clean_data <- function(file_path) {
  # Verificar si el archivo existe
  if (!file.exists(file_path)) {
    stop(paste("[Error] El archivo de datos no fue encontrado en la ruta:", file_path))
  }
  
  # Determinar la extensión del archivo
  ext <- tolower(tools::file_ext(file_path))
  
  # Leer el archivo dependiendo de su extensión
  df <- tryCatch({
    if (ext %in% c("xls", "xlsx")) {
      read_excel(file_path)
    } else {
      read_csv(file_path, show_col_types = FALSE)
    }
  }, error = function(e) {
    stop(paste("[Error] Fallo al leer el archivo. Verifica el formato.", e$message))
  })
  
  # Validar columnas mínimas requeridas
  required_cols <- c("Origen", "Destino")
  missing_cols <- setdiff(required_cols, colnames(df))
  if (length(missing_cols) > 0) {
    stop(paste("[Error] El CSV no contiene las columnas requeridas:", paste(missing_cols, collapse = ", ")))
  }
  
  # IMPORTANTE: Las columnas opcionales deben crearse/normalizarse ANTES de usarlas
  # en operaciones como distinct(). De lo contrario dplyr lanza un error poco descriptivo.

  # Normalizar columna opcional Tipo_Relacion
  if (!"Tipo_Relacion" %in% colnames(df)) {
    df$Tipo_Relacion <- "Desconocido"
  } else {
    df$Tipo_Relacion[is.na(df$Tipo_Relacion)] <- "Desconocido"
  }

  # Normalizar columna opcional Peso
  if (!"Peso" %in% colnames(df)) {
    df$Peso <- 1
  } else {
    # Convertir posibles valores no numéricos a NA, luego sustituir por 1
    df$Peso <- suppressWarnings(as.numeric(df$Peso))
    df$Peso[is.na(df$Peso)] <- 1
  }

  # Limpieza de los datos ya con todas las columnas presentes:
  # - Elimina filas con nodos origen o destino nulos
  # - Elimina relaciones exactamente duplicadas (mismos Origen + Destino + Tipo)
  df_clean <- df %>%
    filter(!is.na(Origen) & !is.na(Destino)) %>%
    distinct(Origen, Destino, Tipo_Relacion, .keep_all = TRUE)
  
  return(df_clean)
}

#' @name generate_graph
#' @description Convierte el dataframe estructurado en un objeto de tipo grafo dirigido.
#' @param df Dataframe limpio (salida de load_and_clean_data).
#' @return Objeto igraph.
generate_graph <- function(df) {
  # Validar que el dataframe no esté vacío tras la limpieza
  if (nrow(df) == 0) {
    stop("[Error] El archivo no contiene relaciones válidas tras la limpieza. Verifica que los campos Origen y Destino no estén todos vacíos.")
  }

  # Extraer listado de nodos únicos (vértices)
  sources <- df %>% distinct(Origen) %>% rename(name = Origen)
  targets <- df %>% distinct(Destino) %>% rename(name = Destino)
  
  nodes <- bind_rows(sources, targets) %>% 
    distinct(name)
  
  # Extraer aristas (relaciones entre nodos)
  # Convertimos Tipo_Relacion a factor para que ggraph/visNetwork puedan
  # mapear colores por categoría correctamente, evitando reciclado silencioso.
  edges <- df %>%
    select(from = Origen, to = Destino, type = Tipo_Relacion, weight = Peso) %>%
    mutate(type = as.factor(type))
  
  # Generar el modelo matemático
  # directed = TRUE asume que la relación va de Origen -> Destino
  g <- graph_from_data_frame(d = edges, vertices = nodes, directed = TRUE)
  
  return(g)
}
