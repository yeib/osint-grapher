# shinyapp/process_data.R
# Módulo de procesamiento de datos para NexusGraph (versión shinyapps.io).
# Idéntico a src/process_data.R — se mantiene en esta carpeta para que
# shinyapps.io pueda bundlear todo en un solo directorio de despliegue.

suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(readxl))
suppressPackageStartupMessages(library(igraph))

load_and_clean_data <- function(file_path, sheet = 1, min_peso = 0, tipos = NULL) {
  if (!file.exists(file_path)) {
    stop(paste("[Error] El archivo de datos no fue encontrado en la ruta:", file_path))
  }
  ext <- tolower(tools::file_ext(file_path))
  df <- tryCatch({
    if (ext %in% c("xls", "xlsx")) {
      if (!is.na(suppressWarnings(as.numeric(sheet)))) sheet <- as.numeric(sheet)
      read_excel(file_path, sheet = sheet)
    } else {
      read_csv(file_path, show_col_types = FALSE)
    }
  }, error = function(e) {
    stop(paste("[Error] Fallo al leer el archivo. Verifica el formato.", e$message))
  })
  required_cols <- c("Origen", "Destino")
  missing_cols <- setdiff(required_cols, colnames(df))
  if (length(missing_cols) > 0) {
    stop(paste("[Error] El CSV no contiene las columnas requeridas:", paste(missing_cols, collapse = ", ")))
  }
  if (!"Tipo_Relacion" %in% colnames(df)) {
    df$Tipo_Relacion <- "Desconocido"
  } else {
    df$Tipo_Relacion[is.na(df$Tipo_Relacion)] <- "Desconocido"
  }
  if (!"Peso" %in% colnames(df)) {
    df$Peso <- 1
  } else {
    df$Peso <- suppressWarnings(as.numeric(df$Peso))
    df$Peso[is.na(df$Peso)] <- 1
  }
  df_clean <- df %>%
    mutate(Origen = trimws(Origen), Destino = trimws(Destino)) %>%
    filter(!is.na(Origen) & !is.na(Destino) & Origen != "" & Destino != "") %>%
    filter(Peso >= min_peso) %>%
    distinct(Origen, Destino, Tipo_Relacion, .keep_all = TRUE)
  if (!is.null(tipos)) {
    df_clean <- df_clean %>% filter(Tipo_Relacion %in% tipos)
  }
  return(df_clean)
}

generate_graph <- function(df, directed = TRUE) {
  if (nrow(df) == 0) {
    stop("[Error] El archivo no contiene relaciones válidas tras la limpieza.")
  }
  sources <- df %>% distinct(Origen) %>% rename(name = Origen)
  targets <- df %>% distinct(Destino) %>% rename(name = Destino)
  nodes   <- bind_rows(sources, targets) %>% distinct(name)
  edges   <- df %>%
    select(from = Origen, to = Destino, type = Tipo_Relacion, weight = Peso) %>%
    mutate(type = as.factor(type))
  g <- graph_from_data_frame(d = edges, vertices = nodes, directed = directed)
  return(g)
}

compute_network_metrics <- function(g) {
  V(g)$degree      <- degree(g, mode = "all")
  V(g)$betweenness <- round(betweenness(g, directed = is_directed(g)), 2)
  if (vcount(g) >= 2) {
    g_undirected <- as_undirected(g, mode = "collapse")
    communities  <- cluster_louvain(g_undirected)
    V(g)$group     <- membership(communities)
    V(g)$community <- paste("Comunidad", membership(communities))
  } else {
    V(g)$group     <- 1L
    V(g)$community <- "Comunidad 1"
  }
  return(g)
}

print_top_nodes <- function(g) {
  if (is.null(V(g)$degree)) return(invisible(NULL))
  nodes_df <- data.frame(
    name        = V(g)$name,
    degree      = V(g)$degree,
    betweenness = V(g)$betweenness,
    community   = V(g)$community,
    stringsAsFactors = FALSE
  )
  top_hubs <- nodes_df %>% arrange(desc(degree), desc(betweenness)) %>% head(5)
  cat("📊 Top Entidades Más Conectadas (Hubs):\n")
  if (nrow(top_hubs) == 0) {
    cat("   (Sin nodos para mostrar)\n")
  } else {
    for (i in seq_len(nrow(top_hubs))) {
      cat(sprintf("   %d. %-15s — %d conexiones (Betweenness: %.2f | %s)\n",
                  i, top_hubs$name[i], top_hubs$degree[i],
                  top_hubs$betweenness[i], top_hubs$community[i]))
    }
  }
  cat("\n")
}
