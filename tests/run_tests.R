# tests/run_tests.R
# Script orquestador de la suite de tests de NexusGraph.
# Ejecutar desde la raíz del proyecto con: Rscript tests/run_tests.R

suppressPackageStartupMessages(library(testthat))

cat("==================================================\n")
cat("   🧪 NexusGraph — Suite de Tests Unitarios\n")
cat("==================================================\n\n")

# Establecer la variable de entorno con la raíz del proyecto.
# Los archivos de test la usan para resolver source() sin depender del CWD.
# Nota: run_tests.R debe ejecutarse desde la raíz del proyecto.
Sys.setenv(NEXUSGRAPH_ROOT = getwd())
cat("📁 Raíz del proyecto:", getwd(), "\n\n")

# Ejecutar todos los archivos test_*.R dentro de la carpeta tests/
# reporter = "progress" muestra el clásico punto por test pasado y 'F' por fallo
results <- test_dir("tests/", reporter = "progress")

cat("\n")

# Extraer el resumen
summary_df <- as.data.frame(results)
total  <- nrow(summary_df)
passed <- sum(!summary_df$failed & !summary_df$error)
failed <- sum(summary_df$failed | summary_df$error)

cat("==================================================\n")
cat(sprintf("  Total: %d  |  ✅ Pasados: %d  |  ❌ Fallidos: %d\n", total, passed, failed))
cat("==================================================\n")

# Salir con código de error si hay fallos (importante para CI/CD)
if (failed > 0) {
  quit(status = 1)
}
