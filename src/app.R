suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(bslib))
suppressPackageStartupMessages(library(shinyjs))
suppressPackageStartupMessages(library(visNetwork))

# En shinyapps.io, el CWD al ejecutar es el directorio de la app.
# Ambos módulos están en el mismo directorio, así que el source es directo.
source(file.path(project_root, "R", "process_data.R"))
source(file.path(project_root, "R", "visualize.R"))

# =============================================================================
# UI
# =============================================================================
ui <- page_sidebar(
  title       = "🕸️ NexusGraph OSINT",
  window_title = "NexusGraph — Análisis de Redes",
  theme       = bs_theme(version = 5, preset = "darkly"),
  fillable    = TRUE,

  sidebar = sidebar(
    width = 320,
    useShinyjs(),

    # ── Datos de entrada ──────────────────────────────────────────────────────
    tags$h6("📂 Datos de Entrada", class = "text-uppercase text-muted fw-bold mb-2"),
    fileInput("file", NULL,
              accept      = c(".csv", ".xls", ".xlsx"),
              buttonLabel = "Elegir archivo…",
              placeholder = "CSV o Excel (.xlsx)"),

    # Datos de demo precargados
    div(class = "text-center mb-2",
      tags$small("¿No tienes datos? ", class = "text-muted"),
      actionLink("load_demo", "Cargar datos Marvel de ejemplo", class = "small")
    ),

    textInput("sheet", "Hoja de Excel (nombre o número)", value = "1"),

    hr(class = "my-2"),

    # ── Filtros ───────────────────────────────────────────────────────────────
    tags$h6("🔍 Filtros", class = "text-uppercase text-muted fw-bold mb-2"),
    numericInput("min_peso", "Peso Mínimo de Relación", value = 0, min = 0, step = 0.5),
    textInput("tipos", "Tipos de Relación (separados por coma)",
              placeholder = "ej: Aliado, Familiar"),
    checkboxInput("undirected", "Grafo No Dirigido (bidireccional)", value = FALSE),

    hr(class = "my-2"),

    # ── Estadísticas de red ───────────────────────────────────────────────────
    tags$h6("📊 Red", class = "text-uppercase text-muted fw-bold mb-2"),
    uiOutput("network_stats"),

    hr(class = "my-2"),

    # ── Exportar ──────────────────────────────────────────────────────────────
    tags$h6("💾 Exportar", class = "text-uppercase text-muted fw-bold mb-2"),
    downloadButton("download_html", "Descargar HTML Interactivo",
                   class = "btn-primary w-100 mb-2"),
    downloadButton("download_png",  "Descargar PNG Estático",
                   class = "btn-outline-secondary w-100"),

    hr(class = "my-3"),
    tags$small(
      class = "text-muted",
      "NexusGraph v0.2.0 · ",
      tags$a("GitHub", href = "https://github.com/yeib/osint-grapher",
             target = "_blank", class = "text-muted")
    )
  ),

  # ── Panel Principal ─────────────────────────────────────────────────────────
  layout_columns(
    col_widths = c(12),

    card(
      full_screen = TRUE,
      card_header(
        class = "d-flex justify-content-between align-items-center",
        "Grafo Interactivo",
        tags$small("Arrastra nodos · Zoom · Hover para detalles", class = "text-muted")
      ),
      # Pantalla de bienvenida
      conditionalPanel(
        condition = "!output.graph_ready",
        div(
          class = "d-flex flex-column align-items-center justify-content-center text-muted",
          style = "height: 480px;",
          tags$div(style = "font-size: 4rem; margin-bottom: 1rem;", "🕸️"),
          tags$h5("Sube tu archivo para comenzar"),
          tags$p(
            "Necesitas un CSV o Excel con columnas: ",
            tags$code("Origen"), ", ", tags$code("Destino"), ".",
            class = "text-center px-4"
          ),
          tags$p(
            "O prueba con el ",
            actionLink("load_demo2", "dataset de Marvel"),
            " desde el panel izquierdo.",
            class = "text-center text-muted small"
          )
        )
      ),
      conditionalPanel(
        condition = "output.graph_ready",
        visNetworkOutput("graph", height = "480px")
      )
    ),

    card(
      card_header("🏆 Top Entidades (Hubs y Puentes)"),
      conditionalPanel(
        condition = "!output.graph_ready",
        p("Las métricas aparecerán aquí una vez que cargues tus datos.", class = "text-muted p-3")
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

# Dataset de demo incluido directamente para evitar dependencias de ruta
DEMO_DATA <- data.frame(
  Origen        = c("Tony Stark","Tony Stark","Tony Stark","Steve Rogers","Steve Rogers",
                    "Thor","Thor","Thor","Thanos","Thanos","Thanos","Gamora","Gamora",
                    "Hulk","Nebula"),
  Destino       = c("Steve Rogers","Thor","Hulk","Thor","Hulk",
                    "Hulk","Thanos","Gamora","Gamora","Nebula","Thor","Nebula","Thanos",
                    "Tony Stark","Thanos"),
  Tipo_Relacion = c("Aliado","Aliado","Aliado","Aliado","Aliado",
                    "Aliado","Enemigo","Enemigo","Aliado","Familiar","Enemigo","Familiar","Enemigo",
                    "Aliado","Familiar"),
  Peso          = c(5,4,3,4,3,3,5,4,5,5,4,4,3,2,3),
  stringsAsFactors = FALSE
)

server <- function(input, output, session) {

  # ── Estado reactivo ─────────────────────────────────────────────────────────
  # Usamos un reactiveVal para almacenar el dataframe (puede venir de archivo o demo)
  data_source <- reactiveVal(NULL)

  # Cargar demo desde el link del sidebar
  observeEvent(input$load_demo,  { data_source(DEMO_DATA) })
  observeEvent(input$load_demo2, { data_source(DEMO_DATA) })

  # Cargar desde archivo subido
  observeEvent(input$file, {
    ext <- tolower(tools::file_ext(input$file$name))
    if (!ext %in% c("csv", "xls", "xlsx")) {
      showNotification(paste("❌ Formato no soportado:", ext), type = "error", duration = 8)
      return()
    }
    tryCatch({
      # Leer primera fila para chequear encabezados
      if (ext %in% c("xls", "xlsx")) {
        tmp_df <- readxl::read_excel(input$file$datapath, n_max = 1)
      } else {
        tmp_df <- readr::read_csv(input$file$datapath, n_max = 1, show_col_types = FALSE)
      }
      
      cols <- colnames(tmp_df)
      if (!("Origen" %in% cols && "Destino" %in% cols)) {
        showModal(modalDialog(
          title = "Mapeo de Columnas",
          p("El CSV no tiene columnas llamadas 'Origen' y 'Destino'. Selecciona cuáles usar:"),
          selectInput("col_origen_map", "Columna de Origen:", choices = cols),
          selectInput("col_destino_map", "Columna de Destino:", choices = cols, selected = if(length(cols)>1) cols[2] else cols[1]),
          selectInput("col_tipo_map", "Columna de Tipo (opcional):", choices = c("Ninguna", cols), selected = "Ninguna"),
          selectInput("col_peso_map", "Columna de Peso (opcional):", choices = c("Ninguna", cols), selected = "Ninguna"),
          footer = tagList(
            modalButton("Cancelar"),
            actionButton("confirm_map", "Aceptar y Generar", class = "btn-primary")
          )
        ))
      } else {
        # Formato clásico
        tipos_filtro <- NULL
        if (trimws(input$tipos) != "") tipos_filtro <- trimws(unlist(strsplit(input$tipos, ",")))
        df <- load_and_clean_data(input$file$datapath, sheet = input$sheet, min_peso = input$min_peso, tipos = tipos_filtro)
        data_source(df)
      }
    }, error = function(e) {
      showNotification(paste("❌ Error al leer el archivo:", e$message), type = "error", duration = 10)
    })
  })

  observeEvent(input$confirm_map, {
    removeModal()
    tryCatch({
      tipos_filtro <- NULL
      if (trimws(input$tipos) != "") tipos_filtro <- trimws(unlist(strsplit(input$tipos, ",")))
      
      df <- load_and_clean_data(input$file$datapath,
                                sheet    = input$sheet,
                                min_peso = input$min_peso,
                                tipos    = tipos_filtro, 
                                col_origen = input$col_origen_map,
                                col_destino = input$col_destino_map,
                                col_peso = if (input$col_peso_map == "Ninguna") "Peso" else input$col_peso_map,
                                col_tipo = if (input$col_tipo_map == "Ninguna") "Tipo_Relacion" else input$col_tipo_map)
      data_source(df)
    }, error = function(e) {
      showNotification(paste("❌ Error al procesar:", e$message), type = "error", duration = 10)
    })
  })

  # ── Grafo reactivo ──────────────────────────────────────────────────────────
  graph_data <- reactive({
    df <- data_source()
    req(df)

    id <- showNotification("⏳ Construyendo el grafo…", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)

    tryCatch({
      # Aplicar filtros si vienen de los inputs (cuando el origen es archivo)
      if (!is.null(input$file)) {
        tipos_filtro <- NULL
        if (trimws(input$tipos) != "") {
          tipos_filtro <- trimws(unlist(strsplit(input$tipos, ",")))
        }
        df <- df %>%
          dplyr::filter(Peso >= input$min_peso)
        if (!is.null(tipos_filtro)) {
          df <- df %>% dplyr::filter(Tipo_Relacion %in% tipos_filtro)
        }
      }

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

  # ── Stats en sidebar ────────────────────────────────────────────────────────
  output$network_stats <- renderUI({
    g <- graph_data()
    if (is.null(g)) return(p("— sin datos —", class = "text-muted small"))
    n_com <- length(unique(V(g)$group))
    tagList(
      div(class = "d-flex justify-content-between",
          span("Entidades (nodos)"), tags$strong(vcount(g))),
      div(class = "d-flex justify-content-between",
          span("Relaciones (aristas)"), tags$strong(ecount(g))),
      div(class = "d-flex justify-content-between",
          span("Comunidades detectadas"), tags$strong(n_com))
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
    content  = function(file) {
      g <- graph_data()
      req(g)
      generate_interactive_html(g, file)
    }
  )

  # ── Descarga PNG ─────────────────────────────────────────────────────────────
  output$download_png <- downloadHandler(
    filename = function() paste0("nexusgraph-", Sys.Date(), ".png"),
    content  = function(file) {
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
