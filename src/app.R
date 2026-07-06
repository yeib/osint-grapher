suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(bslib))
suppressPackageStartupMessages(library(shinyjs))
suppressPackageStartupMessages(library(visNetwork))

# Resolver la raíz del proyecto de forma robusta usando variable de entorno.
# nexusgraph.sh --web la pasa como NEXUSGRAPH_ROOT. Si se ejecuta directamente
# con `Rscript src/app.R`, usamos el directorio padre del script como fallback.
project_root <- Sys.getenv("NEXUSGRAPH_ROOT", unset = "")
if (project_root == "") {
  # Fallback: intentar resolver desde la ubicación del archivo
  script_path <- tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) NULL)
  if (!is.null(script_path) && basename(dirname(script_path)) == "src") {
    project_root <- dirname(dirname(script_path))
  } else {
    project_root <- getwd()
  }
}
source(file.path(project_root, "R", "process_data.R"))
source(file.path(project_root, "R", "visualize.R"))

# =============================================================================
# UI
# =============================================================================
ui <- page_sidebar(
  title = tags$span(
    tags$img(src = "https://raw.githubusercontent.com/yeib/osint-grapher/main/data/icon.png",
             height = "24px", style = "margin-right:8px; vertical-align:middle;",
             onerror = "this.style.display='none'"),
    "NexusGraph OSINT"
  ),
  window_title = "NexusGraph — Análisis de Redes",
  theme = bs_theme(version = 5, preset = "darkly"),
  fillable = TRUE,

  sidebar = sidebar(
    width = 320,
    useShinyjs(),

    # ── Sección 1: Datos ──────────────────────────────────────────────────────
    tags$h6("📂 Datos de Entrada", class = "text-uppercase text-muted fw-bold mb-2"),
    fileInput("file", NULL,
              accept = c(".csv", ".xls", ".xlsx"),
              buttonLabel = "Elegir archivo…",
              placeholder = "CSV o Excel (.xlsx)"),
    textInput("sheet", "Hoja de Excel (nombre o número)", value = "1"),

    hr(class = "my-2"),

    # ── Sección 2: Filtros ────────────────────────────────────────────────────
    tags$h6("🔍 Filtros", class = "text-uppercase text-muted fw-bold mb-2"),
    numericInput("min_peso", "Peso Mínimo de Relación", value = 0, min = 0, step = 0.5),
    textInput("tipos", "Tipos de Relación (separados por coma)",
              placeholder = "ej: Aliado, Familiar"),
    checkboxInput("undirected", "Grafo No Dirigido (bidireccional)", value = FALSE),

    hr(class = "my-2"),

    # ── Sección 3: Métricas ───────────────────────────────────────────────────
    tags$h6("📊 Red", class = "text-uppercase text-muted fw-bold mb-2"),
    uiOutput("network_stats"),

    hr(class = "my-2"),

    # ── Sección 4: Exportar ───────────────────────────────────────────────────
    tags$h6("💾 Exportar", class = "text-uppercase text-muted fw-bold mb-2"),
    downloadButton("download_html", "Descargar HTML Interactivo",
                   class = "btn-primary w-100 mb-2"),
    downloadButton("download_png",  "Descargar PNG Estático",
                   class = "btn-outline-secondary w-100")
  ),

  # ── Panel Principal ─────────────────────────────────────────────────────────
  layout_columns(
    col_widths = c(12),

    # Grafo
    card(
      full_screen = TRUE,
      card_header(
        class = "d-flex justify-content-between align-items-center",
        "Grafo Interactivo",
        tags$small("Arrastra nodos · Zoom · Hover para detalles", class = "text-muted")
      ),
      # Pantalla de bienvenida cuando no hay datos
      conditionalPanel(
        condition = "!output.graph_ready",
        div(
          class = "d-flex flex-column align-items-center justify-content-center text-muted",
          style = "height: 500px;",
          tags$i(class = "fs-1 mb-3", "🕸️"),
          tags$h5("Sin datos cargados"),
          tags$p("Sube un archivo CSV o Excel desde el panel izquierdo para comenzar.",
                 class = "text-center px-4"),
          tags$code("Origen, Destino, Tipo_Relacion, Peso")
        )
      ),
      conditionalPanel(
        condition = "output.graph_ready",
        visNetworkOutput("graph", height = "500px")
      )
    ),

    # Top Nodos
    card(
      card_header("🏆 Top Entidades (Hubs y Puentes)"),
      conditionalPanel(
        condition = "!output.graph_ready",
        p("Las métricas de red aparecerán aquí una vez que cargues tus datos.",
          class = "text-muted p-3")
      ),
      conditionalPanel(
        condition = "output.graph_ready",
        verbatimTextOutput("top_nodes")
      )
    )
  )
)

# =============================================================================
# Server
# =============================================================================
server <- function(input, output, session) {

  # ── Reactive: procesar grafo ────────────────────────────────────────────────
  graph_data <- reactive({
    req(input$file)

    # Validar extensión del archivo
    ext <- tolower(tools::file_ext(input$file$name))
    if (!ext %in% c("csv", "xls", "xlsx")) {
      showNotification(
        paste("❌ Formato no soportado:", ext, "— Usa CSV o Excel."),
        type = "error", duration = 8
      )
      return(NULL)
    }

    # Mostrar notificación de procesamiento
    id <- showNotification("⏳ Procesando datos…", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)

    tryCatch({
      tipos_filtro <- NULL
      if (trimws(input$tipos) != "") {
        tipos_filtro <- trimws(unlist(strsplit(input$tipos, ",")))
      }

      df <- load_and_clean_data(
        input$file$datapath,
        sheet    = input$sheet,
        min_peso = input$min_peso,
        tipos    = tipos_filtro
      )
      g <- generate_graph(df, directed = !input$undirected)
      g <- compute_network_metrics(g)
      return(g)

    }, error = function(e) {
      showNotification(paste("❌ Error:", e$message), type = "error", duration = 10)
      return(NULL)
    })
  })

  # ── Flag para conditionalPanel ──────────────────────────────────────────────
  output$graph_ready <- reactive({ !is.null(graph_data()) })
  outputOptions(output, "graph_ready", suspendWhenHidden = FALSE)

  # ── Estadísticas de red en sidebar ─────────────────────────────────────────
  output$network_stats <- renderUI({
    g <- graph_data()
    if (is.null(g)) {
      return(p("— sin datos —", class = "text-muted small"))
    }
    n_comunidades <- length(unique(V(g)$group))
    tagList(
      div(class = "d-flex justify-content-between",
        span("Entidades (nodos)"),
        tags$strong(vcount(g))
      ),
      div(class = "d-flex justify-content-between",
        span("Relaciones (aristas)"),
        tags$strong(ecount(g))
      ),
      div(class = "d-flex justify-content-between",
        span("Comunidades detectadas"),
        tags$strong(n_comunidades)
      )
    )
  })

  # ── Grafo interactivo ────────────────────────────────────────────────────────
  output$graph <- renderVisNetwork({
    g <- graph_data()
    req(g)
    build_visnetwork_object(g)
  })

  # ── Top nodos ───────────────────────────────────────────────────────────────
  output$top_nodes <- renderPrint({
    g <- graph_data()
    req(g)
    print_top_nodes(g)
  })

  # ── Descarga HTML ────────────────────────────────────────────────────────────
  output$download_html <- downloadHandler(
    filename = function() paste0("nexusgraph-", Sys.Date(), ".html"),
    content = function(file) {
      g <- graph_data()
      req(g)
      generate_interactive_html(g, file)
    }
  )

  # ── Descarga PNG ─────────────────────────────────────────────────────────────
  # Shiny pasa un path temporal SIN extensión: escribimos en tmp.png y copiamos.
  output$download_png <- downloadHandler(
    filename = function() paste0("nexusgraph-", Sys.Date(), ".png"),
    content = function(file) {
      g <- graph_data()
      req(g)
      tmp <- paste0(file, ".png")
      generate_static_report(g, tmp)
      file.copy(tmp, file)
      file.remove(tmp)
    }
  )
}

shinyApp(ui, server)
