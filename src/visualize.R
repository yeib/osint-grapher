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
build_visnetwork_object <- function(g) {
  # Extraer datos de la estructura igraph a formato visNetwork
  data <- toVisNetworkData(g)
  
  # Configurar estética de los nodos (diseño corporativo y limpio)
  data$nodes$shape <- "dot"
  data$nodes$color.border <- "#1a365d"
  data$nodes$font.color <- "#2d3748"
  data$nodes$shadow <- TRUE
  
  # Si no hay grupos (comunidades), usar el azul por defecto
  if (!"group" %in% colnames(data$nodes)) {
    data$nodes$color.background <- "#2a4365"
  }
  
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
                    width = "100%", height = "800px") %>%
    visOptions(
      highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE), # Resalta vecinos al hacer hover
      nodesIdSelection = TRUE # Permite buscar por nombre de nodo
    ) %>%
    visPhysics(
      stabilization = TRUE,
      solver = "forceAtlas2Based" # Motor físico óptimo para grafos densos
    ) %>%
    visEdges(
      arrows = "to", 
      color = list(color = "#a0aec0", highlight = "#3182ce")
    ) %>%
    visInteraction(
      navigationButtons = TRUE, 
      zoomView = TRUE
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
    p <- ggraph(g, layout = 'fr') + 
      # Configurar aristas
      geom_edge_link(aes(edge_alpha = weight, edge_width = weight, color = type), 
                     arrow = arrow(length = unit(2, 'mm')), 
                     end_cap = circle(4, 'mm')) + 
      # Configurar nodos (color por comunidad detección automática)
      geom_node_point(aes(color = as.factor(group)), size = 6, alpha = 0.8) + 
      # Etiquetas de nodos, usando ggrepel para evitar solapamientos
      geom_node_text(aes(label = name), repel = TRUE, size = 3, fontface = "bold", color = "#1a202c") +
      # Estilo y tema
      theme_graph(background = "white") +
      labs(title = "NexusGraph: Inteligencia de Fuentes Abiertas",
           subtitle = "Esquema estático de las entidades y sus relaciones",
           caption = paste("Generado el:", Sys.time())) +
      # Escala de color explícita para evitar fallos con factor de un solo nivel
      scale_edge_color_discrete(na.value = "grey50") +
      theme(legend.position = "bottom", legend.title = element_blank())
    
    # Exportar a disco
    ggsave(output_path, plot = p, width = 12, height = 9, bg = "white", dpi = 300)
    cat("[Éxito] Reporte estático de alta resolución exportado en:", output_path, "\n")
  }, error = function(e) {
    stop(paste("[Error] Fallo al generar gráfico estático:", e$message))
  })
  invisible(output_path)  # Retornar ruta para composabilidad
}
