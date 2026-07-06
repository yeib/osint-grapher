suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(bslib))
suppressPackageStartupMessages(library(shinyjs))
suppressPackageStartupMessages(library(visNetwork))

# Resolver la raíz del proyecto relativa a este archivo, sin depender del CWD.
# Cuando se lanza desde nexusgraph.sh --web, el CWD ya es la raíz. 
# Cuando se lanza directamente con `Rscript src/app.R`, necesitamos subir un nivel.
app_dir <- normalizePath(dirname(sys.frame(1)$ofile), mustWork = FALSE)
if (basename(app_dir) == "src") {
  project_root <- dirname(app_dir)
} else {
  project_root <- app_dir  # Ya estamos en la raíz
}
source(file.path(project_root, "src", "process_data.R"))
source(file.path(project_root, "src", "visualize.R"))


# Definir la interfaz de usuario usando bslib (diseño moderno y limpio)
ui <- page_sidebar(
  title = "NexusGraph OSINT",
  theme = bs_theme(version = 5, preset = "darkly"), # Tema oscuro elegante
  
  sidebar = sidebar(
    width = 350,
    useShinyjs(),
    
    h5("1. Datos de Entrada"),
    fileInput("file", "Subir CSV o Excel (.xlsx)", accept = c(".csv", ".xls", ".xlsx"), buttonLabel = "Explorar..."),
    textInput("sheet", "Hoja de Excel (si aplica)", value = "1"),
    
    hr(),
    
    h5("2. Filtros"),
    numericInput("min_peso", "Peso Mínimo", value = 0, min = 0),
    textInput("tipos", "Tipos de Relación (separados por coma, ej: Aliado,Familiar)"),
    checkboxInput("undirected", "Grafo No Dirigido (bidireccional)", value = FALSE),
    
    hr(),
    
    h5("3. Exportar"),
    downloadButton("download_html", "Descargar HTML", class = "btn-primary w-100"),
    br(), br(),
    downloadButton("download_png", "Descargar PNG estático", class = "btn-secondary w-100")
  ),
  
  # Panel Principal
  layout_columns(
    col_widths = c(12),
    
    card(
      full_screen = TRUE,
      card_header("Grafo Interactivo (Mover, hacer zoom y arrastrar nodos)"),
      visNetworkOutput("graph", height = "550px")
    ),
    
    card(
      card_header("Métricas Top (Hubs y Puentes)"),
      verbatimTextOutput("top_nodes")
    )
  )
)

# Lógica del servidor
server <- function(input, output, session) {
  
  # Función reactiva que procesa el grafo solo cuando cambian los inputs
  graph_data <- reactive({
    req(input$file)
    
    # Manejo de errores para no crashear la app web
    tryCatch({
      tipos_filtro <- NULL
      if (trimws(input$tipos) != "") {
        tipos_filtro <- trimws(unlist(strsplit(input$tipos, ",")))
      }
      
      df <- load_and_clean_data(input$file$datapath, sheet = input$sheet, min_peso = input$min_peso, tipos = tipos_filtro)
      g <- generate_graph(df, directed = !input$undirected)
      g <- compute_network_metrics(g)
      return(g)
      
    }, error = function(e) {
      showNotification(paste("Error en los datos:", e$message), type = "error", duration = 10)
      return(NULL)
    })
  })
  
  # Renderizar el gráfico interactivo
  output$graph <- renderVisNetwork({
    g <- graph_data()
    req(g)
    build_visnetwork_object(g)
  })
  
  # Renderizar las métricas
  output$top_nodes <- renderPrint({
    g <- graph_data()
    req(g)
    print_top_nodes(g)
  })
  
  # Manejador de descarga HTML
  output$download_html <- downloadHandler(
    filename = function() {
      paste("nexusgraph-", Sys.Date(), ".html", sep="")
    },
    content = function(file) {
      g <- graph_data()
      req(g)
      generate_interactive_html(g, file)
    }
  )
  
  # Manejador de descarga PNG
  output$download_png <- downloadHandler(
    filename = function() {
      paste("nexusgraph-", Sys.Date(), ".png", sep="")
    },
    content = function(file) {
      g <- graph_data()
      req(g)
      generate_static_report(g, file)
    }
  )
}

# Iniciar la aplicación
shinyApp(ui, server)
