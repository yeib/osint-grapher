#!/usr/bin/env Rscript
# deploy_shinyapps.R
# Script para publicar NexusGraph en shinyapps.io
#
# USO:
#   1. Crea tu cuenta en https://www.shinyapps.io
#   2. Ve a Account → Tokens → Show → Show Secret
#   3. Copia los 3 valores y ejecuta:
#
#   Rscript deploy_shinyapps.R --account TU_CUENTA --token TU_TOKEN --secret TU_SECRET
#
# O configura las variables de entorno:
#   SHINYAPPS_ACCOUNT, SHINYAPPS_TOKEN, SHINYAPPS_SECRET
#   y simplemente: Rscript deploy_shinyapps.R

suppressPackageStartupMessages(library(rsconnect))

# ── Parsear argumentos o usar variables de entorno ────────────────────────────
args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(args, flag, env_var) {
  idx <- which(args == flag)
  if (length(idx) > 0 && idx < length(args)) return(args[idx + 1])
  val <- Sys.getenv(env_var, unset = "")
  if (val != "") return(val)
  return(NULL)
}

account <- get_arg(args, "--account", "SHINYAPPS_ACCOUNT")
token   <- get_arg(args, "--token",   "SHINYAPPS_TOKEN")
secret  <- get_arg(args, "--secret",  "SHINYAPPS_SECRET")

if (is.null(account) || is.null(token) || is.null(secret) || account == "" || token == "" || secret == "") {
  cat("❌ ERROR: Faltan credenciales de shinyapps.io.\n")
  cat("Si estás en GitHub Actions, debes configurar los siguientes Repository Secrets:\n")
  cat("  - SHINYAPPS_ACCOUNT\n")
  cat("  - SHINYAPPS_TOKEN\n")
  cat("  - SHINYAPPS_SECRET\n\n")
  cat("Uso local:\n")
  cat("  Rscript deploy_shinyapps.R --account TU_CUENTA --token TU_TOKEN --secret TU_SECRET\n\n")
  cat("Obtén tus credenciales en: https://www.shinyapps.io → Account → Tokens\n")
  quit(status = 1)
}

# ── Configurar credenciales ───────────────────────────────────────────────────
cat("🔐 Configurando credenciales de shinyapps.io...\n")
rsconnect::setAccountInfo(
  name   = account,
  token  = token,
  secret = secret
)

# ── Deploy ────────────────────────────────────────────────────────────────────
cat("🚀 Desplegando NexusGraph en shinyapps.io...\n")
cat("   → Cuenta:", account, "\n")
cat("   → App:    nexusgraph\n\n")

cat("🔍 Chequeando dependencias locales antes de deployar...\n")
tryCatch({
  deps <- rsconnect::appDependencies("shinyapp")
  cat("✅ Encontradas", nrow(deps), "dependencias.\n")
}, error = function(e) {
  cat("⚠️ Advertencia al buscar dependencias:", e$message, "\n")
})

tryCatch({
  # Forzar el repositorio a un espejo de CRAN estándar para evitar que ShinyApps.io 
  # intente descargar paquetes usando el esquema "RSPM/src/contrib" de GitHub Actions
  options(repos = c(CRAN = "https://cloud.r-project.org"))
  
  rsconnect::deployApp(
    appDir    = "shinyapp",         # Directorio con app.R y módulos
    appName   = "nexusgraph",       # Nombre de la app en shinyapps.io
    account   = account,
    forceUpdate = TRUE,
    launch.browser = FALSE          # No abrir el navegador en VPS
  )
  
  cat("\n✅ ¡Publicado!\n")
  cat("   → URL: https://", account, ".shinyapps.io/nexusgraph/\n", sep = "")
}, error = function(e) {
  cat("\n❌ ERROR CRÍTICO durante el despliegue:\n")
  cat("Mensaje de error:\n", e$message, "\n\n")
  cat("Revisa si:\n")
  cat("1. Las credenciales son correctas (Token/Secret)\n")
  cat("2. Todos los paquetes requeridos por app.R están en el DESCRIPTION\n")
  quit(status = 1)
})
