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

if (is.null(account) || is.null(token) || is.null(secret)) {
  cat("❌ Faltan credenciales de shinyapps.io.\n\n")
  cat("Uso:\n")
  cat("  Rscript deploy_shinyapps.R --account TU_CUENTA --token TU_TOKEN --secret TU_SECRET\n\n")
  cat("O con variables de entorno:\n")
  cat("  SHINYAPPS_ACCOUNT=xxx SHINYAPPS_TOKEN=xxx SHINYAPPS_SECRET=xxx Rscript deploy_shinyapps.R\n\n")
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

rsconnect::deployApp(
  appDir    = "shinyapp",         # Directorio con app.R y módulos
  appName   = "nexusgraph",       # Nombre de la app en shinyapps.io
  account   = account,
  forceUpdate = TRUE,
  launch.browser = FALSE          # No abrir el navegador en VPS
)

cat("\n✅ ¡Publicado!\n")
cat("   → URL: https://", account, ".shinyapps.io/nexusgraph/\n", sep = "")
