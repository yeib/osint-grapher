#!/bin/bash
# Wrapper script para NexusGraph.
# Permite invocar el análisis directamente desde la terminal.

# Detectar el directorio donde vive este script y hacer cd a él.
# Esto garantiza que las rutas relativas funcionen sin importar
# desde qué directorio el usuario invoque el script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Verificar que R esté instalado y accesible en el PATH
if ! command -v Rscript &> /dev/null; then
    echo "Error: Rscript no está instalado o no está en el PATH."
    echo "Por favor, instala R. Más info: https://www.r-project.org/"
    exit 1
fi

# Pasar todos los argumentos recibidos directamente a main.R
Rscript src/main.R "$@"
