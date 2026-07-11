#' @title Generador de Visualizaciones para NexusGraph
#' @description 
#' Este módulo provee funciones especializadas para exportar
#' el grafo a diferentes formatos: HTML interactivo (visNetwork)
#' y reportes estáticos en alta definición (ggplot2/ggraph).

suppressPackageStartupMessages(library(igraph))
suppressPackageStartupMessages(library(visNetwork))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(ggraph))
# ggrepel debe cargarse explícitamente: ggraph lo invoca internamente para
# geom_node_text(repel = TRUE), pero requiere que el namespace esté disponible.
suppressPackageStartupMessages(library(ggrepel))
suppressPackageStartupMessages(library(htmltools)) # Para escapar HTML en tooltips

#' @name build_visnetwork_object
#' @description Crea el widget interactivo de visNetwork sin guardarlo a disco. Útil para Shiny.
#' @param g Objeto igraph.
#' @return Objeto visNetwork.
build_visnetwork_object <- function(g, height = "100%") {
  is_dir <- is_directed(g)  # Detectar si el grafo es dirigido o no
  # Extraer datos de la estructura igraph a formato visNetwork
  data <- toVisNetworkData(g)
  
  # Configurar estética de los nodos
  data$nodes$shape <- "dot"
  data$nodes$font.color <- "#ffffff" # Texto blanco legible
  data$nodes$shadow <- TRUE
  
  # Si no hay grupos (comunidades), usar el azul por defecto
  if (!"group" %in% colnames(data$nodes)) {
    data$nodes$color.background <- "#2a4365"
  }
  
  # Tooltips para dar feedback visual al hacer hover en nodos
  data$nodes$title <- htmlEscape(paste("Entidad:", data$nodes$name))
  
  # Configurar propiedades de las aristas (edges)
  if ("type" %in% colnames(data$edges)) {
    # htmlEscape evita inyección de HTML malicioso desde los datos del CSV
    data$edges$title <- htmlEscape(paste("Tipo de relación:", data$edges$type))
  }
  
  # Asignar grosor de aristas basado en su peso
  if ("weight" %in% colnames(data$edges)) {
    data$edges$value <- data$edges$weight
  }
  
  # Construir la visualización interactiva
  vis <- visNetwork(nodes = data$nodes, edges = data$edges, 
                    main = "NexusGraph", submain = "Análisis Interactivo de Vínculos", 
                    width = "100%", height = height) %>%
    visNodes(
      borderWidth = 1,
      borderWidthSelected = 3,
      color = list(
        hover = list(border = "#ffffff") # Borde blanco brillante al hacer hover, mantiene el color del nodo
      )
    ) %>%
    visOptions(
      highlightNearest = list(enabled = TRUE, degree = 1, hover = FALSE),
      nodesIdSelection = TRUE
    ) %>%
    visPhysics(
      solver = "forceAtlas2Based",
      forceAtlas2Based = list(damping = 0.8, avoidOverlap = 0.8),
      stabilization = list(enabled = TRUE, iterations = 400)
    ) %>%
    visEvents(
      type = "once",
      stabilizationIterationsDone = "function() { this.setOptions({physics: false}); }",
      stabilized = "function() { this.setOptions({physics: false}); }"
    ) %>%
    visEdges(
      arrows = if (is_dir) "to" else "",
      color = list(color = "#a0aec0", highlight = "#3182ce")
    ) %>%
    visInteraction(
      navigationButtons = TRUE, 
      zoomView = TRUE,
      hover = TRUE
    )
    
  return(vis)
}

#' @name generate_interactive_html
#' @description Crea un archivo HTML independiente con el visor de grafos de red.
#' @param g Objeto igraph.
#' @param output_path Ruta destino donde se guardará el HTML.
#' @return Ninguno (exporta archivo a disco).
generate_interactive_html <- function(g, output_path) {
  vis <- build_visnetwork_object(g)
  
  # Crear carpeta destino si no existe
  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
  
  # Guardar el widget en HTML auto-contenido
  tryCatch({
    visSave(vis, file = output_path, selfcontained = TRUE)
    cat("[Éxito] Reporte interactivo exportado en:", output_path, "\n")
  }, error = function(e) {
    stop(paste("[Error] No se pudo guardar el archivo HTML:", e$message))
  })
  invisible(output_path)  # Retornar ruta para composabilidad
}

#' @name generate_static_report
#' @description Crea un reporte en imagen (PNG, JPEG o PDF). Ideal para adjuntar en informes impresos.
#' @param g Objeto igraph.
#' @param output_path Ruta destino donde se guardará la imagen.
#' @return Ninguno (exporta archivo a disco).
generate_static_report <- function(g, output_path) {
  # Verificar extensión soportada
  ext <- tolower(tools::file_ext(output_path))
  supported_exts <- c("png", "jpg", "jpeg", "pdf")
  
  if (!(ext %in% supported_exts)) {
    warning(paste("[Aviso] Formato", ext, "no reconocido. Procediendo como PNG por defecto."))
    output_path <- paste0(tools::file_path_sans_ext(output_path), ".png")
  }
  
  # Crear carpeta destino si no existe
  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
  
  # Renderizado gráfico con ggraph (diseño Fruchterman-Reingold)
  tryCatch({
    is_dir <- is_directed(g)
    p <- ggraph(g, layout = 'fr') + 
      # Configurar aristas
      geom_edge_link(aes(edge_alpha = weight, edge_width = weight, color = type), 
                     arrow = if (is_dir) arrow(length = unit(2, 'mm')) else NULL,
                     end_cap = circle(4, 'mm')) + 
      # Configurar nodos (color por comunidad detección automática)\
      geom_node_point(aes(color = as.factor(group)), size = 6, alpha = 0.8) + 
      # Etiquetas de nodos, usando ggrepel para evitar solapamientos
      geom_node_text(aes(label = name), repel = TRUE, size = 3, fontface = "bold", color = "#1a202c") +
      # Estilo y tema
      theme_graph(background = "white") +
      labs(title = "NexusGraph: Inteligencia de Fuentes Abiertas",
           subtitle = "Esquema estático de las entidades y sus relaciones",
           caption = paste("Generado el:", Sys.time())) +
      # Escalas explícitas para evitar warnings de ggplot2 con datasets uniformes
      scale_edge_alpha(range = c(0.3, 1), guide = "none") +
      scale_edge_width(range = c(0.5, 3), guide = "none") +
      scale_edge_color_discrete(na.value = "grey50") +
      theme(legend.position = "bottom", legend.title = element_blank())
    
    # Exportar a disco con dispositivo PNG explícito (evita problemas en entornos headless)
    ggsave(output_path, plot = p, width = 12, height = 9, bg = "white", dpi = 300, device = "png")
    cat("[Éxito] Reporte estático de alta resolución exportado en:", output_path, "\n")
  }, error = function(e) {
    stop(paste("[Error] Fallo al generar gráfico estático:", e$message))
  })
  invisible(output_path)  # Retornar ruta para composabilidad
}
