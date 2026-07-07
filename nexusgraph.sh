#!/bin/bash
# Wrapper script para NexusGraph.
# Permite invocar el análisis CLI o la interfaz web desde la terminal.

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

# Parsear argumentos para detectar --web y --port en cualquier posición
WEB_MODE=false
PORT=3838
CLI_ARGS=()

for arg in "$@"; do
    case "$arg" in
        --web)
            WEB_MODE=true
            ;;
        --port=*)
            PORT="${arg#--port=}"
            if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
                echo "❌ Error: --port debe ser un número entero. Recibido: '$PORT'"
                exit 1
            fi
            ;;
        *)
            CLI_ARGS+=("$arg")
            ;;
    esac
done

if [ "$WEB_MODE" = true ]; then
    echo "=================================================="
    echo " 🌐 Iniciando NexusGraph Web UI"
    echo " → http://localhost:${PORT}"
    echo "=================================================="
    # Pasamos la raíz del proyecto como variable de entorno para que app.R
    # pueda resolver sus rutas sin depender del CWD ni de sys.frame() hacks.
    NEXUSGRAPH_ROOT="$SCRIPT_DIR" \
        Rscript -e "shiny::runApp('shinyapp', port=${PORT}, host='0.0.0.0', launch.browser=FALSE)"
else
    # Pasar todos los argumentos CLI directamente a main.R
    Rscript src/main.R "${CLI_ARGS[@]}"
fi
