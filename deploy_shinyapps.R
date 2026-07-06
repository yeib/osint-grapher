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
  # =========================================================================
  # FIX para GitHub Actions + ShinyApps.io + RSPM:
  # setup-r-dependencies instala desde RSPM y marca el DESCRIPTION con "Repository: RSPM".
  # rsconnect/renv copia esto al manifest.json, y ShinyApps.io explota al intentar 
  # leer la URL "RSPM/src/contrib/...".
  # Si ponemos "CRAN", explota diciendo "CRAN/src/contrib/...".
  # Solución: Reescribir "Repository: RSPM" a "Repository: https://cloud.r-project.org" 
  # en TODOS los paquetes para forzar una URL válida.
  # =========================================================================
  cat("🔧 Aplicando fix de repositorios (RSPM -> HTTPS CRAN) en la librería local...\n")
  for (lib in .libPaths()) {
    pkgs <- list.files(lib, full.names = TRUE)
    for (pkg in pkgs) {
      desc_file <- file.path(pkg, "DESCRIPTION")
      if (file.exists(desc_file)) {
        lines <- readLines(desc_file, warn = FALSE)
        if (any(grepl("Repository:.*RSPM", lines) | grepl("Repository:.*CRAN", lines))) {
          lines <- gsub("Repository:.*RSPM", "Repository: https://cloud.r-project.org", lines)
          lines <- gsub("Repository:.*CRAN", "Repository: https://cloud.r-project.org", lines)
          writeLines(lines, desc_file)
        }
      }
    }
  }
  options(repos = c(CRAN = "https://cloud.r-project.org"))
  cat("✅ Fix de repositorios (URL) aplicado.\n\n")

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
