# install_packages.R
# Script de conveniencia para instalar todas las dependencias necesarias de NexusGraph

cat("Verificando e instalando paquetes de R requeridos para NexusGraph...\n\n")

# Lista de paquetes requeridos
required_packages <- c(
  "dplyr", 
  "readr", 
  "readxl",     # Leer Excel
  "igraph",     # Lógica matemática de grafos
  "visNetwork", # Generación del HTML interactivo
  "ggplot2",    # Base para gráficos estáticos
  "ggraph",     # Geometrías de grafos para ggplot2
  "ggrepel",    # Etiquetas que no se solapan
  "optparse",   # Parseo de argumentos de consola
  "htmltools",  # Escapado seguro de HTML en tooltips
  "shiny",      # Interfaz gráfica local
  "bslib",      # Temas modernos (Bootstrap 5) para Shiny
  "shinyjs"     # Funciones extra de JS para Shiny
)

# Detectar cuáles faltan
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]

# Instalar los faltantes (dependencies=TRUE garantiza que las subdependencias
# como libxml2, glpk, etc. también se instalen cuando son paquetes R puro)
if (length(new_packages)) {
  cat("Se instalarán los siguientes paquetes:", paste(new_packages, collapse = ", "), "\n")
  install.packages(new_packages, repos = "https://cran.rstudio.com/", dependencies = TRUE)
} else {
  cat("¡Todos los paquetes necesarios ya están instalados!\n")
}

# Verificar post-instalación: confirmar que todo quedó bien
still_missing <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]
if (length(still_missing) > 0) {
  cat("\n❌ ERROR: Los siguientes paquetes no pudieron instalarse:", paste(still_missing, collapse = ", "), "\n")
  cat("Revisa los errores de instalación arriba e intenta instalarlos manualmente.\n")
  quit(status = 1)
}

cat("\n✅ Dependencias verificadas correctamente. ¡Listo para usar NexusGraph!\n")

