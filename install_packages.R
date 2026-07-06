# install_packages.R
# Script de conveniencia para instalar todas las dependencias necesarias de NexusGraph

cat("Verificando e instalando paquetes de R requeridos para NexusGraph...\n\n")

# Lista de paquetes requeridos
required_packages <- c(
  "dplyr", 
  "readr", 
  "readxl", # Soporte para archivos Excel (.xlsx)
  "igraph", 
  "visNetwork", 
  "ggplot2", 
  "ggraph", 
  "ggrepel",  # Requerido por geom_node_text(repel = TRUE) en ggraph
  "optparse"
)

# Detectar cuáles faltan
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]

# Instalar los faltantes
if(length(new_packages)) {
  cat("Se instalarán los siguientes paquetes:", paste(new_packages, collapse = ", "), "\n")
  install.packages(new_packages, repos = "https://cran.rstudio.com/")
} else {
  cat("¡Todos los paquetes necesarios ya están instalados!\n")
}

cat("\nDependencias verificadas correctamente. ¡Listo para usar NexusGraph!\n")
