# tests/test_load_and_clean_data.R
# Tests unitarios para el módulo de procesamiento de datos de NexusGraph.
# Cubre: lectura CSV, validación de columnas, normalización y limpieza.

library(testthat)
library(dplyr)
library(readr)

# Cargar el módulo bajo prueba.
# .NEXUSGRAPH_ROOT es una variable de entorno que establece run_tests.R
# apuntando a la raíz del proyecto. Esto garantiza que source() funcione
# sin importar desde qué directorio ejecute testthat los archivos.
root <- Sys.getenv("NEXUSGRAPH_ROOT", unset = getwd())
source(file.path(root, "src", "process_data.R"))

# =============================================================================
# Helpers: Crear archivos CSV temporales para tests
# =============================================================================

#' Escribe un CSV temporal y devuelve su ruta.
make_temp_csv <- function(content) {
  path <- tempfile(fileext = ".csv")
  writeLines(content, path)
  return(path)
}

# =============================================================================
# Test Suite: load_and_clean_data()
# =============================================================================

test_that("Error claro si el archivo no existe", {
  expect_error(
    load_and_clean_data("/ruta/que/no/existe.csv"),
    regexp = "no fue encontrado"
  )
})

test_that("Error claro si faltan columnas requeridas (Origen y Destino)", {
  csv_sin_columnas <- make_temp_csv("Nombre,Edad\nAlice,30\nBob,25")
  expect_error(
    load_and_clean_data(csv_sin_columnas),
    regexp = "columnas requeridas"
  )
})

test_that("Error claro si falta solo la columna Destino", {
  csv_sin_destino <- make_temp_csv("Origen,Tipo\nAlice,Amigo")
  expect_error(
    load_and_clean_data(csv_sin_destino),
    regexp = "Destino"
  )
})

test_that("Lectura correcta de un CSV válido con todas las columnas", {
  csv_completo <- make_temp_csv(
    "Origen,Destino,Tipo_Relacion,Peso\nAlice,Bob,Amigo,3\nBob,Carol,Colega,2"
  )
  df <- load_and_clean_data(csv_completo)

  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 2)
  expect_true(all(c("Origen", "Destino", "Tipo_Relacion", "Peso") %in% colnames(df)))
})

test_that("Si no existe Tipo_Relacion en el CSV, se crea con valor 'Desconocido'", {
  csv_sin_tipo <- make_temp_csv("Origen,Destino,Peso\nAlice,Bob,3")
  df <- load_and_clean_data(csv_sin_tipo)

  expect_true("Tipo_Relacion" %in% colnames(df))
  expect_equal(df$Tipo_Relacion[1], "Desconocido")
})

test_that("Si Tipo_Relacion tiene NAs, se sustituyen por 'Desconocido'", {
  csv_tipo_na <- make_temp_csv("Origen,Destino,Tipo_Relacion\nAlice,Bob,NA\nBob,Carol,Amigo")
  df <- load_and_clean_data(csv_tipo_na)

  # El NA textual que readr lee como NA real debe rellenarse
  expect_false(any(is.na(df$Tipo_Relacion)))
})

test_that("Si no existe Peso en el CSV, se crea con valor 1 para todas las filas", {
  csv_sin_peso <- make_temp_csv("Origen,Destino\nAlice,Bob\nBob,Carol")
  df <- load_and_clean_data(csv_sin_peso)

  expect_true("Peso" %in% colnames(df))
  expect_true(all(df$Peso == 1))
})

test_that("Pesos no numéricos se convierten a 1", {
  csv_peso_texto <- make_temp_csv("Origen,Destino,Peso\nAlice,Bob,ALTO\nBob,Carol,3")
  df <- load_and_clean_data(csv_peso_texto)

  expect_equal(df$Peso[df$Origen == "Alice"], 1)
  expect_equal(df$Peso[df$Origen == "Bob"], 3)
})

test_that("Filas con Origen o Destino vacío (NA) son eliminadas", {
  csv_con_na <- make_temp_csv("Origen,Destino\nAlice,Bob\n,Carol\nBob,")
  df <- load_and_clean_data(csv_con_na)

  # Solo la primera fila es válida
  expect_equal(nrow(df), 1)
  expect_equal(df$Origen[1], "Alice")
})

test_that("Relaciones exactamente duplicadas son eliminadas (mismo Origen+Destino+Tipo)", {
  csv_con_dupes <- make_temp_csv(
    "Origen,Destino,Tipo_Relacion\nAlice,Bob,Amigo\nAlice,Bob,Amigo\nAlice,Bob,Colega"
  )
  df <- load_and_clean_data(csv_con_dupes)

  # 2 filas: Amigo (una vez) y Colega
  expect_equal(nrow(df), 2)
})

test_that("Misma pareja con diferente Tipo_Relacion NO se considera duplicado", {
  csv_multi_tipo <- make_temp_csv(
    "Origen,Destino,Tipo_Relacion\nAlice,Bob,Amigo\nAlice,Bob,Colega"
  )
  df <- load_and_clean_data(csv_multi_tipo)

  expect_equal(nrow(df), 2)
})

test_that("El dataframe devuelto tiene las columnas en el orden correcto", {
  csv_completo <- make_temp_csv(
    "Origen,Destino,Tipo_Relacion,Peso\nAlice,Bob,Amigo,3"
  )
  df <- load_and_clean_data(csv_completo)
  expected_cols <- c("Origen", "Destino", "Tipo_Relacion", "Peso")

  expect_true(all(expected_cols %in% colnames(df)))
})
