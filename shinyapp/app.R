suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(bslib))
suppressPackageStartupMessages(library(visNetwork))

# En shinyapps.io, el CWD al ejecutar es el directorio de la app.
# Ambos módulos están en el mismo directorio, así que el source es directo.
source("process_data.R")
source("visualize.R")

# =============================================================================
# UI
# =============================================================================
ui <- page_sidebar(
  title       = "NexusGraph · OSINT Network Analyzer",
  window_title = "NexusGraph · OSINT Network Analyzer",
  theme       = bs_theme(
    version = 5,
    bg = "#0d1117",
    fg = "#e6edf3",
    primary = "#1f6feb",
    secondary = "#8b949e",
    base_font = font_google("Inter"),
    code_font = font_google("JetBrains Mono")
  ),
  fillable    = TRUE,

  tags$head(
    tags$link(rel = "canonical", href = "https://nexusgraph.yeib.cl/"),
    tags$meta(name = "description", content = "NexusGraph: Plataforma de análisis y visualización interactiva de grafos y redes OSINT."),
    tags$link(rel = "icon", type = "image/png", sizes = "48x48", href = "https://nexusgraph.yeib.cl/favicon-48x48.png"),
    tags$link(rel = "icon", type = "image/png", sizes = "96x96", href = "https://nexusgraph.yeib.cl/favicon-96x96.png"),
    tags$link(rel = "icon", type = "image/png", sizes = "192x192", href = "https://nexusgraph.yeib.cl/favicon-192x192.png"),
    tags$link(rel = "icon", type = "image/png", sizes = "512x512", href = "https://nexusgraph.yeib.cl/favicon.png"),
    tags$link(rel = "icon", type = "image/svg+xml", href = "https://nexusgraph.yeib.cl/favicon.svg"),
    tags$link(rel = "apple-touch-icon", href = "https://nexusgraph.yeib.cl/apple-touch-icon.png"),
    tags$link(rel = "shortcut icon", href = "https://nexusgraph.yeib.cl/favicon.ico", type = "image/x-icon"),
    tags$style(HTML("
      :root { --ng-border: #30363d; --ng-surface: #161b22; }
      body { background: #0d1117; color: #e6edf3; }
      .navbar, .bslib-page-title {
        background: #0d1117 !important;
        border-bottom: 1px solid rgba(255, 255, 255, 0.1);
      }
      .navbar .navbar-brand { color: #e6edf3; font-weight: 600; }
      .bslib-sidebar-layout > .sidebar { background: #0d1117; border-right: 1px solid var(--ng-border); }
      .card, .accordion-item {
        background: var(--ng-surface);
        border: 1px solid var(--ng-border) !important;
        border-radius: 0.75rem;
        box-shadow: none;
      }
      .card-header, .accordion-item {
        background: var(--ng-surface);
        border-color: var(--ng-border);
      }
      .accordion-button,
      .accordion-button:not(.collapsed),
      .accordion-button.collapsed {
        background-color: #161b22 !important;
        color: #e6edf3 !important;
        border-color: var(--ng-border) !important;
        font-weight: 500;
      }
      .accordion-button:not(.collapsed) {
        box-shadow: inset 0 -1px 0 var(--ng-border) !important;
      }
      .accordion-button:focus { box-shadow: 0 0 0 0.15rem rgba(31, 111, 235, 0.2); }
      .accordion-button::after { filter: invert(0.8); }
      .accordion-collapse, .accordion-body {
        background-color: #0d1117 !important;
        color: #c9d1d9 !important;
      }
      .form-control, .form-select, .input-group-text {
        color: #e6edf3; background-color: #0d1117; border-color: var(--ng-border);
      }
      .form-control::placeholder { color: #8b949e; }
      .btn { border-radius: 0.45rem; font-weight: 500; transition: background-color 120ms ease, border-color 120ms ease; }
      .btn:hover { transform: none; }
      .btn-primary, .btn-info {
        color: #fff; background: #1f6feb; border-color: #1f6feb; box-shadow: none;
      }
      .btn-primary:hover, .btn-info:hover { color: #fff; background: #388bfd; border-color: #388bfd; }
      .btn-outline-info, .btn-outline-secondary {
        color: #c9d1d9; background: #21262d; border-color: var(--ng-border);
      }
      .btn-outline-info:hover, .btn-outline-secondary:hover {
        color: #e6edf3; background: #30363d; border-color: #8b949e;
      }
      .ng-kpi-strip {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 0.5rem;
        margin-bottom: 0.6rem;
      }
      .ng-kpi-chip {
        display: inline-flex;
        align-items: center;
        gap: 0.45rem;
        background: #161b22;
        border: 1px solid #30363d;
        border-radius: 6px;
        padding: 0.25rem 0.75rem;
        font-size: 0.8rem;
        box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
      }
      .ng-kpi-label {
        color: #8b949e;
        font-weight: 500;
        font-size: 0.72rem;
        text-transform: uppercase;
        letter-spacing: 0.04em;
      }
      .ng-kpi-val {
        color: #58a6ff;
        font-family: 'JetBrains Mono', monospace;
        font-weight: 700;
        font-size: 0.9rem;
      }
      .ng-graph-card { position: relative; }
      .bslib-full-screen-enter, .bslib-full-screen-exit {
        width: 30px !important;
        height: 30px !important;
        min-width: 30px !important;
        min-height: 30px !important;
        max-width: 30px !important;
        max-height: 30px !important;
        padding: 0 !important;
        display: inline-flex !important;
        align-items: center !important;
        justify-content: center !important;
        position: absolute !important;
        top: 8px !important;
        right: 12px !important;
        border-radius: 6px !important;
        background: #21262d !important;
        border: 1px solid #30363d !important;
        color: #c9d1d9 !important;
        cursor: pointer !important;
        z-index: 25 !important;
        box-shadow: none !important;
      }
      .bslib-full-screen-enter:hover, .bslib-full-screen-exit:hover {
        background: #30363d !important;
        color: #fff !important;
      }
      .ng-graph-card > .card-header { padding-right: 3.5rem; }
      .ng-empty-state { min-height: 480px; padding: 3rem 1.5rem; }
      .ng-empty-state .lead { color: #8b949e; font-size: 1rem; }
      .table { --bs-table-bg: transparent; --bs-table-color: #c9d1d9; }
      .table thead th { color: #8b949e; font-size: 0.8rem; font-weight: 500; }
      .ng-rank, .ng-degree { color: #c9d1d9; background: #21262d; border: 1px solid #30363d; }
      .ng-community-1, .ng-community-2, .ng-community-3,
      .ng-community-4, .ng-community-5, .ng-community-6 {
        color: #c9d1d9; background: #21262d; border: 1px solid #30363d;
      }
      .ng-mono { font-family: 'JetBrains Mono', monospace; }
      #global-loader {
        display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%;
        background: rgba(13, 17, 23, 0.9); z-index: 99999; color: #e6edf3; text-align: center;
        flex-direction: column; justify-content: center; align-items: center;
      }
      html.shiny-busy #global-loader { display: flex !important; }
      .spinner-border { width: 3rem; height: 3rem; margin-bottom: 1rem; color: #8b949e; }
      .card:fullscreen #graph, .card:-webkit-full-screen #graph,
      .card[data-full-screen='true'] #graph,
      .card:fullscreen .vis-network, .card:-webkit-full-screen .vis-network,
      .card[data-full-screen='true'] .vis-network {
        height: calc(100vh - 100px) !important;
        width: 100% !important;
      }
      /* visNetwork canvas y controles interiores ordenados */
      .vis-network {
        position: relative !important;
        overflow: hidden !important;
        width: 100% !important;
      }
      div.vis-network div.vis-navigation {
        position: absolute !important;
        top: 0 !important;
        left: 0 !important;
        width: 100% !important;
        height: 100% !important;
        pointer-events: none !important;
        z-index: 10 !important;
      }
      div.vis-network div.vis-navigation div.vis-button {
        pointer-events: auto !important;
        display: block !important;
        width: 32px !important;
        height: 32px !important;
        background-color: #21262d !important;
        border: 1px solid #30363d !important;
        border-radius: 6px !important;
        box-shadow: 0 2px 6px rgba(0,0,0,0.5) !important;
        transition: background-color 0.15s ease, transform 0.15s ease !important;
        filter: invert(0.85) hue-rotate(180deg) !important;
      }
      div.vis-network div.vis-navigation div.vis-button:hover {
        background-color: #30363d !important;
        filter: invert(1) !important;
        transform: scale(1.05);
      }
      /* Pad de flechas en esquina inferior izquierda */
      div.vis-network div.vis-navigation div.vis-button.vis-up {
        top: auto !important;
        bottom: 84px !important;
        left: 48px !important;
      }
      div.vis-network div.vis-navigation div.vis-button.vis-down {
        top: auto !important;
        bottom: 16px !important;
        left: 48px !important;
      }
      div.vis-network div.vis-navigation div.vis-button.vis-left {
        top: auto !important;
        bottom: 50px !important;
        left: 14px !important;
      }
      div.vis-network div.vis-navigation div.vis-button.vis-right {
        top: auto !important;
        bottom: 50px !important;
        left: 82px !important;
      }
      /* Botones de zoom y centrado (reset) en esquina inferior derecha */
      div.vis-network div.vis-navigation div.vis-button.vis-zoomIn {
        top: auto !important;
        bottom: 92px !important;
        right: 16px !important;
      }
      div.vis-network div.vis-navigation div.vis-button.vis-zoomOut {
        top: auto !important;
        bottom: 54px !important;
        right: 16px !important;
      }
      div.vis-network div.vis-navigation div.vis-button.vis-zoomExtends {
        top: auto !important;
        bottom: 16px !important;
        right: 16px !important;
      }
    "))
  ),

  sidebar = sidebar(
    width = 320,
    bslib::accordion(
      open = c("datos", "filtros"),
      bslib::accordion_panel(
        "Datos de entrada",
        value = "datos",
        fileInput("file", NULL, accept = c(".csv", ".xls", ".xlsx"),
                  buttonLabel = "Elegir archivo", placeholder = "CSV o Excel (.xlsx)"),
        actionLink("load_demo", "Cargar dataset de ejemplo",
                   class = "btn btn-outline-info w-100 mb-3"),
        textInput("sheet", "Hoja de Excel (nombre o número)", value = "1")
      ),
      bslib::accordion_panel(
        "Filtros de red",
        value = "filtros",
        numericInput("min_peso", "Peso mínimo de conexión", value = 0, min = 0, step = 0.5),
        textInput("tipos", "Tipos de relación",
                  placeholder = "Separados por coma"),
        checkboxInput("undirected", "Grafo no dirigido", value = FALSE)
      ),
      bslib::accordion_panel(
        "Configuración de columnas",
        value = "configuracion",
        p("Selecciona las columnas del archivo para definir los extremos de cada relación.",
          class = "small text-muted"),
        actionButton("btn_remap", "Re-mapear columnas", class = "btn-outline-secondary w-100")
      ),
      bslib::accordion_panel(
        "Exportar",
        value = "exportar",
        downloadButton("download_html", "Descargar HTML interactivo",
                       class = "btn-primary w-100 mb-2"),
        downloadButton("download_png", "Descargar PNG estático",
                       class = "btn-outline-secondary w-100")
      )
    ),
    div(class = "mt-4 pt-3 border-top border-secondary text-center",
      tags$small(
        class = "text-muted",
        "NexusGraph v0.4.0 · ",
        tags$a(href = "https://github.com/yeib/osint-grapher", "GitHub", target = "_blank",
               class = "text-decoration-none")
      ),
      br(),
      tags$small(
        class = "text-muted",
        "Creado por ",
        tags$a("Yeib", href = "https://yeib.cl", target = "_blank",
               class = "text-light text-decoration-none fw-semibold"),
        " · ",
        HTML("<!--email_off--><a href=\"mailto:yeib@pm.me\" class=\"text-muted text-decoration-none\">yeib@pm.me</a><!--/email_off-->")
      )
    )
  ),

  # ── Panel Principal ─────────────────────────────────────────────────────────
  layout_columns(
    col_widths = c(12),
    fill = FALSE,
    fillable = FALSE,

    tags$div(id = "global-loader",
      tags$div(class = "spinner-border", role = "status"),
      tags$h3("Procesando datos pesados..."),
      tags$p("Por favor espera, no cierres esta ventana.", class = "text-muted")
    ),

    uiOutput("network_kpis"),

    card(
      min_height = "600px",
      full_screen = TRUE,
      class = "ng-graph-card",
      card_header(
        "Grafo interactivo"
      ),
      conditionalPanel(
        condition = "!output.graph_ready",
        div(class = "ng-empty-state d-flex flex-column align-items-center justify-content-center text-center",
          tags$h3("Análisis y Visualización de Relaciones", class = "fw-semibold mb-3"),
          tags$p(
            "Carga un archivo CSV o Excel con columnas de Origen y Destino para mapear la red.",
            class = "lead mb-4"
          ),
          actionButton("load_demo2", "Cargar dataset de ejemplo (Marvel)",
                       class = "btn btn-outline-secondary px-4")
        )
      ),
      conditionalPanel(
        condition = "output.graph_ready",
        visNetworkOutput("graph", height = "600px")
      )
    ),

    card(
      card_header("Entidades destacadas"),
      conditionalPanel(
        condition = "!output.graph_ready",
        p("Las métricas aparecerán aquí una vez que cargues tus datos.", class = "text-muted p-3")
      ),
      conditionalPanel(
        condition = "output.graph_ready",
        uiOutput("top_nodes_table")
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

  show_mapping_modal <- function(cols, description, accept_label) {
    showModal(modalDialog(
      title = "Mapeo de columnas",
      p(description),
      selectInput("col_origen_map", "Columna de origen:", choices = cols),
      selectInput("col_destino_map", "Columna de destino:", choices = cols,
                  selected = if (length(cols) > 1) cols[2] else cols[1]),
      selectInput("col_tipo_map", "Columna de tipo (opcional):",
                  choices = c("Ninguna", cols), selected = "Ninguna"),
      selectInput("col_peso_map", "Columna de peso (opcional):",
                  choices = c("Ninguna", cols), selected = "Ninguna"),
      footer = tagList(
        modalButton("Cancelar"),
        actionButton("confirm_map", accept_label, class = "btn-primary")
      )
    ))
  }

  # Re-mapear columnas
  observeEvent(input$btn_remap, {
    req(input$file)
    ext <- tolower(tools::file_ext(input$file$name))
    tryCatch({
      if (ext %in% c("xls", "xlsx")) {
        tmp_df <- readxl::read_excel(input$file$datapath, n_max = 1)
      } else {
        tmp_df <- readr::read_csv(input$file$datapath, n_max = 1, show_col_types = FALSE)
      }
      cols <- colnames(tmp_df)
      show_mapping_modal(
        cols,
        "Selecciona las columnas del archivo que deseas utilizar.",
        "Aceptar y recalcular"
      )
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })

  # Cargar desde archivo subido
  observeEvent(input$file, {
    withProgress(message = "Subiendo y analizando archivo...", detail = "Por favor espera...", value = 0.5, {
      ext <- tolower(tools::file_ext(input$file$name))
      if (!ext %in% c("csv", "xls", "xlsx")) {
        showNotification(paste("Formato no soportado:", ext), type = "error", duration = 8)
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
          show_mapping_modal(
            cols,
            "El archivo no tiene columnas llamadas Origen y Destino. Selecciona cuáles usar.",
            "Aceptar y generar"
          )
        } else {
          incProgress(0.3, detail = "Leyendo datos completos...")
          # Cargar los datos puros sin filtros, para que graph_data() aplique los filtros dinámicamente
          df <- load_and_clean_data(input$file$datapath, sheet = input$sheet, min_peso = 0, tipos = NULL, ext = ext)
          data_source(df)
          incProgress(0.2, detail = "¡Listo!")
        }
      }, error = function(e) {
        showNotification(paste("Error al leer el archivo:", e$message), type = "error", duration = 10)
      })
    })
  })

  observeEvent(input$confirm_map, {
    removeModal()
    withProgress(message = "Procesando archivo con mapeo...", detail = "Mapeando columnas...", value = 0.5, {
      tryCatch({
        # Cargar los datos puros sin filtros
        df <- load_and_clean_data(input$file$datapath,
                                  sheet    = input$sheet,
                                  min_peso = 0,
                                  tipos    = NULL, 
                                  col_origen = input$col_origen_map,
                                  col_destino = input$col_destino_map,
                                  col_peso = if (input$col_peso_map == "Ninguna") "Peso" else input$col_peso_map,
                                  col_tipo = if (input$col_tipo_map == "Ninguna") "Tipo_Relacion" else input$col_tipo_map,
                                  ext = tolower(tools::file_ext(input$file$name)))
        data_source(df)
        incProgress(0.5, detail = "¡Listo!")
      }, error = function(e) {
        showNotification(paste("Error al procesar:", e$message), type = "error", duration = 10)
      })
    })
  })

  # ── Grafo reactivo ──────────────────────────────────────────────────────────
  graph_data <- reactive({
    df <- data_source()
    req(df)

    withProgress(message = "Construyendo el grafo...", detail = "Aplicando filtros y calculando métricas...", value = 0.3, {
      tryCatch({
        # Aplicar filtros SIEMPRE, independiente de si el origen es demo o archivo.
        # Esto garantiza que los sliders reaccionen de forma consistente en ambos casos.
        tipos_filtro <- NULL
        if (trimws(input$tipos) != "") {
          tipos_filtro <- trimws(unlist(strsplit(input$tipos, ",")))
        }
        # Manejar el caso donde el usuario borra el input numérico dejándolo en NA
        min_p <- input$min_peso
        if (is.na(min_p)) min_p <- 0
        
        df <- df %>% dplyr::filter(Peso >= min_p)
        if (!is.null(tipos_filtro)) {
          df <- df %>% dplyr::filter(Tipo_Relacion %in% tipos_filtro)
        }

        incProgress(0.3, detail = "Generando red interactiva...")
        g <- generate_graph(df, directed = !input$undirected)
        
        incProgress(0.3, detail = "Calculando centralidades y comunidades...")
        g <- compute_network_metrics(g)
        
        incProgress(0.1, detail = "¡Completado!")
        return(g)
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
        return(NULL)
      })
    })
  })

  # ── Flag para conditionalPanel ──────────────────────────────────────────────
  output$graph_ready <- reactive({ !is.null(graph_data()) })
  outputOptions(output, "graph_ready", suspendWhenHidden = FALSE)

  output$network_kpis <- renderUI({
    g <- graph_data()
    if (is.null(g)) return(NULL)
    nodes <- format(vcount(g), big.mark = ",", scientific = FALSE)
    edges <- format(ecount(g), big.mark = ",", scientific = FALSE)
    communities <- length(unique(V(g)$group))

    div(class = "ng-kpi-strip",
      div(class = "ng-kpi-chip",
        span(class = "ng-kpi-label", "Entidades:"),
        span(class = "ng-kpi-val", nodes)
      ),
      div(class = "ng-kpi-chip",
        span(class = "ng-kpi-label", "Conexiones:"),
        span(class = "ng-kpi-val", edges)
      ),
      div(class = "ng-kpi-chip",
        span(class = "ng-kpi-label", "Comunidades:"),
        span(class = "ng-kpi-val", communities)
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
  output$top_nodes_table <- renderUI({
    g <- graph_data()
    req(g)
    nodes <- get_top_nodes_data(g, n = 5)
    if (nrow(nodes) == 0) {
      return(p("No hay entidades para mostrar con los filtros actuales.",
               class = "text-muted p-3"))
    }

    rows <- lapply(seq_len(nrow(nodes)), function(i) {
      community_index <- ((as.integer(nodes$group[i]) - 1L) %% 6L) + 1L
      tags$tr(
        tags$td(span(class = "badge rounded-pill ng-rank", paste0("#", i))),
        tags$td(tags$strong(nodes$name[i])),
        tags$td(span(class = "badge ng-degree ng-mono", nodes$degree[i])),
        tags$td(span(class = "ng-mono", format(nodes$betweenness[i], nsmall = 2))),
        tags$td(span(class = paste("badge rounded-pill",
                                   paste0("ng-community-", community_index)),
                     nodes$community[i]))
      )
    })

    div(class = "table-responsive",
      tags$table(class = "table table-dark table-hover table-sm align-middle mb-0",
        tags$thead(tags$tr(
          tags$th("Rango", scope = "col"),
          tags$th("Entidad", scope = "col"),
          tags$th("Conexiones", scope = "col"),
          tags$th("Betweenness", scope = "col"),
          tags$th("Comunidad", scope = "col")
        )),
        tags$tbody(rows)
      )
    )
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
      on.exit(if (file.exists(tmp)) file.remove(tmp), add = TRUE)
      generate_static_report(g, tmp)
      file.copy(tmp, file)
    }
  )
}

shinyApp(ui, server)
