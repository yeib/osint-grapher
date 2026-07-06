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
#' @param sheet Hoja de Excel a leer (si aplica).
#' @param min_peso Umbral mínimo de peso para incluir la relación.
#' @param tipos Vector de tipos de relación a incluir (NULL para todos).
#' @param col_origen Nombre de la columna que representa el Origen (default: "Origen")
#' @param col_destino Nombre de la columna que representa el Destino (default: "Destino")
#' @param col_peso Nombre de la columna que representa el Peso (default: "Peso")
#' @param col_tipo Nombre de la columna que representa el Tipo_Relacion (default: "Tipo_Relacion")
#' @return Un dataframe limpio con las columnas Origen, Destino, Tipo_Relacion y Peso.
load_and_clean_data <- function(file_path, sheet = 1, min_peso = 0, tipos = NULL,
                                col_origen = "Origen", col_destino = "Destino", 
                                col_peso = "Peso", col_tipo = "Tipo_Relacion") {
  # Verificar si el archivo existe
  if (!file.exists(file_path)) {
    stop(paste("[Error] El archivo de datos no fue encontrado en la ruta:", file_path))
  }
  
  # Determinar la extensión del archivo
  ext <- tolower(tools::file_ext(file_path))
  
  # Leer el archivo dependiendo de su extensión
  df <- tryCatch({
    if (ext %in% c("xls", "xlsx")) {
      # Si sheet es número en string, intentar convertir
      if (!is.na(suppressWarnings(as.numeric(sheet)))) {
        sheet <- as.numeric(sheet)
      }
      read_excel(file_path, sheet = sheet)
    } else {
      read_csv(file_path, show_col_types = FALSE)
    }
  }, error = function(e) {
    stop(paste("[Error] Fallo al leer el archivo. Verifica el formato.", e$message))
  })
  
  # Mapeo dinámico de columnas
  if (col_origen %in% colnames(df)) colnames(df)[colnames(df) == col_origen] <- "Origen"
  if (col_destino %in% colnames(df)) colnames(df)[colnames(df) == col_destino] <- "Destino"
  if (col_peso %in% colnames(df)) colnames(df)[colnames(df) == col_peso] <- "Peso"
  if (col_tipo %in% colnames(df)) colnames(df)[colnames(df) == col_tipo] <- "Tipo_Relacion"
  
  # Validar columnas mínimas requeridas
  required_cols <- c("Origen", "Destino")
  missing_cols <- setdiff(required_cols, colnames(df))
  if (length(missing_cols) > 0) {
    stop(paste("[Error] El CSV no contiene las columnas seleccionadas como Origen/Destino. (Seleccionado:", col_origen, "y", col_destino, ")"))
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
  # - Normaliza strings (trimws) para evitar que " Alice" y "Alice" sean entidades distintas
  # - Elimina filas con nodos origen o destino nulos
  # - Elimina relaciones exactamente duplicadas (mismos Origen + Destino + Tipo)
  df_clean <- df %>%
    mutate(Origen = trimws(Origen), Destino = trimws(Destino)) %>%
    filter(!is.na(Origen) & !is.na(Destino) & Origen != "" & Destino != "") %>%
    filter(Peso >= min_peso) %>%
    distinct(Origen, Destino, Tipo_Relacion, .keep_all = TRUE)
  
  # Filtrar por tipos de relación si se especificaron
  if (!is.null(tipos)) {
    df_clean <- df_clean %>% filter(Tipo_Relacion %in% tipos)
  }

  
  return(df_clean)
}

#' @name generate_graph
#' @description Convierte el dataframe estructurado en un objeto de tipo grafo dirigido o no dirigido.
#' @param df Dataframe limpio (salida de load_and_clean_data).
#' @param directed Lógico, TRUE para grafo dirigido.
#' @return Objeto igraph.
generate_graph <- function(df, directed = TRUE) {
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
  g <- graph_from_data_frame(d = edges, vertices = nodes, directed = directed)
  
  return(g)
}

#' @name compute_network_metrics
#' @description Calcula centralidades y comunidades, agregándolas como atributos a los nodos.
#' @param g Grafo igraph.
#' @return Grafo igraph con nuevos atributos en sus vértices.
compute_network_metrics <- function(g) {
  # Métricas de centralidad
  V(g)$degree <- degree(g, mode = "all")
  V(g)$betweenness <- round(betweenness(g, directed = is_directed(g)), 2)
  
  # Detección de comunidades (clusters)
  # cluster_louvain requiere al menos 2 nodos. Con 1 nodo, asignamos comunidad 1 directamente.
  if (vcount(g) >= 2) {
    g_undirected <- as_undirected(g, mode = "collapse")
    communities <- cluster_louvain(g_undirected)
    V(g)$group <- membership(communities)
    V(g)$community <- paste("Comunidad", membership(communities))
  } else {
    V(g)$group <- 1L
    V(g)$community <- "Comunidad 1"
  }
  
  return(g)
}


#' @name print_top_nodes
#' @description Imprime un reporte por consola de los nodos más conectados (hubs).
#' @param g Grafo igraph con métricas calculadas.
print_top_nodes <- function(g) {
  # Validar que el grafo tenga métricas calculadas
  if (is.null(V(g)$degree)) {
    cat("[Aviso] Métricas no calculadas. Ejecuta compute_network_metrics() primero.\n")
    return(invisible(NULL))
  }
  
  # Extraer datos de nodos
  nodes_df <- data.frame(
    name = V(g)$name,
    degree = V(g)$degree,
    betweenness = V(g)$betweenness,
    community = V(g)$community,
    stringsAsFactors = FALSE
  )
  
  top_hubs <- nodes_df %>% 
    arrange(desc(degree), desc(betweenness)) %>% 
    head(5)
  
  cat("\ud83d\udcca Top Entidades Más Conectadas (Hubs):\n")
  
  # Proteger contra dataframe vacío
  if (nrow(top_hubs) == 0) {
    cat("   (Sin nodos para mostrar con los filtros actuales)\n")
  } else {
    for (i in seq_len(nrow(top_hubs))) {
      cat(sprintf("   %d. %-15s \u2014 %d conexiones (Betweenness: %.2f | %s)\n", 
                  i, top_hubs$name[i], top_hubs$degree[i], top_hubs$betweenness[i], top_hubs$community[i]))
    }
  }
  cat("\n")
}

