# shinyapp/visualize.R
# Módulo de visualización para NexusGraph (versión shinyapps.io).

suppressPackageStartupMessages(library(igraph))
suppressPackageStartupMessages(library(visNetwork))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(ggraph))
suppressPackageStartupMessages(library(ggrepel))
suppressPackageStartupMessages(library(htmltools))

build_visnetwork_object <- function(g) {
  data <- toVisNetworkData(g)
  data$nodes$shape        <- "dot"
  data$nodes$color.border <- "#1a365d"
  data$nodes$font.color   <- "#2d3748"
  data$nodes$shadow       <- TRUE
  if (!"group" %in% colnames(data$nodes)) {
    data$nodes$color.background <- "#2a4365"
  }
  if ("type" %in% colnames(data$edges)) {
    data$edges$title <- htmlEscape(paste("Tipo de relación:", data$edges$type))
  }
  if ("weight" %in% colnames(data$edges)) {
    data$edges$value <- data$edges$weight
  }
  vis <- visNetwork(
    nodes = data$nodes, edges = data$edges,
    main = "NexusGraph", submain = "Análisis Interactivo de Vínculos",
    width = "100%", height = "100%"
  ) %>%
    visOptions(
      highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE),
      nodesIdSelection = TRUE
    ) %>%
    visPhysics(stabilization = TRUE, solver = "forceAtlas2Based") %>%
    visEdges(arrows = "to", color = list(color = "#a0aec0", highlight = "#3182ce")) %>%
    visInteraction(navigationButtons = TRUE, zoomView = TRUE)
  return(vis)
}

generate_interactive_html <- function(g, output_path) {
  vis <- build_visnetwork_object(g)
  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
  tryCatch({
    visSave(vis, file = output_path, selfcontained = TRUE)
  }, error = function(e) {
    stop(paste("[Error] No se pudo guardar el archivo HTML:", e$message))
  })
  invisible(output_path)
}

generate_static_report <- function(g, output_path) {
  ext <- tolower(tools::file_ext(output_path))
  if (!ext %in% c("png", "jpg", "jpeg", "pdf")) {
    output_path <- paste0(tools::file_path_sans_ext(output_path), ".png")
  }
  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
  tryCatch({
    p <- ggraph(g, layout = 'fr') +
      geom_edge_link(aes(edge_alpha = weight, edge_width = weight, color = type),
                     arrow = arrow(length = unit(2, 'mm')),
                     end_cap = circle(4, 'mm')) +
      geom_node_point(aes(color = as.factor(group)), size = 6, alpha = 0.8) +
      geom_node_text(aes(label = name), repel = TRUE, size = 3,
                     fontface = "bold", color = "#1a202c") +
      theme_graph(background = "white") +
      labs(title    = "NexusGraph: Inteligencia de Fuentes Abiertas",
           subtitle = "Esquema estático de las entidades y sus relaciones",
           caption  = paste("Generado el:", Sys.time())) +
      scale_edge_color_discrete(na.value = "grey50") +
      theme(legend.position = "bottom", legend.title = element_blank())
    ggsave(output_path, plot = p, width = 12, height = 9, bg = "white", dpi = 300)
  }, error = function(e) {
    stop(paste("[Error] Fallo al generar gráfico estático:", e$message))
  })
  invisible(output_path)
}
