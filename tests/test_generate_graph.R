# tests/test_generate_graph.R
# Tests unitarios para el módulo de generación de grafos de NexusGraph.
# Cubre: estructura del grafo, conteo de nodos/aristas, validaciones, atributos.

library(testthat)
library(dplyr)
library(igraph)

# Cargar el módulo bajo prueba.
# .NEXUSGRAPH_ROOT es una variable de entorno que establece run_tests.R
# apuntando a la raíz del proyecto.
root <- Sys.getenv("NEXUSGRAPH_ROOT", unset = getwd())
source(file.path(root, "R", "process_data.R"))

# =============================================================================
# Helper: Crear dataframes de prueba directamente (sin necesidad de archivos)
# =============================================================================

#' Crea un dataframe limpio de prueba con las columnas esperadas por generate_graph().
make_clean_df <- function(
    origenes   = c("Alice", "Bob"),
    destinos   = c("Bob", "Carol"),
    tipos      = c("Amigo", "Colega"),
    pesos      = c(3, 2)
) {
  data.frame(
    Origen       = origenes,
    Destino      = destinos,
    Tipo_Relacion = tipos,
    Peso         = pesos,
    stringsAsFactors = FALSE
  )
}

# =============================================================================
# Test Suite: generate_graph()
# =============================================================================

test_that("Error claro si el dataframe está vacío", {
  df_vacio <- make_clean_df(
    origenes = character(0), destinos = character(0),
    tipos = character(0), pesos = numeric(0)
  )
  expect_error(
    generate_graph(df_vacio),
    regexp = "relaciones válidas"
  )
})

test_that("Devuelve un objeto de clase igraph", {
  df <- make_clean_df()
  g <- generate_graph(df)

  expect_true(is_igraph(g))
})

test_that("El grafo es dirigido", {
  df <- make_clean_df()
  g <- generate_graph(df)

  expect_true(is_directed(g))
})

test_that("El número de nodos es correcto (nodos únicos en Origen + Destino)", {
  # Alice -> Bob -> Carol: 3 nodos únicos
  df <- make_clean_df(
    origenes = c("Alice", "Bob"),
    destinos = c("Bob",   "Carol"),
    tipos    = c("Amigo", "Colega"),
    pesos    = c(1, 1)
  )
  g <- generate_graph(df)

  expect_equal(vcount(g), 3)
})

test_that("El número de aristas es correcto", {
  df <- make_clean_df()
  g <- generate_graph(df)

  # 2 filas en el df = 2 aristas
  expect_equal(ecount(g), 2)
})

test_that("Un nodo que aparece solo como Destino también se incluye correctamente", {
  # Carol aparece solo como Destino, nunca como Origen
  df <- make_clean_df(
    origenes = c("Alice", "Bob"),
    destinos = c("Bob",   "Carol"),
    tipos    = c("A", "B"),
    pesos    = c(1, 1)
  )
  g <- generate_graph(df)
  nodos <- V(g)$name

  expect_true("Carol" %in% nodos)
  expect_true("Alice" %in% nodos)
})

test_that("No hay nodos duplicados aunque aparezcan en Origen y Destino", {
  # Bob aparece como Origen y como Destino: debe contar UNA sola vez
  df <- make_clean_df(
    origenes = c("Alice", "Bob"),
    destinos = c("Bob",   "Carol"),
    tipos    = c("A", "B"),
    pesos    = c(1, 1)
  )
  g <- generate_graph(df)
  nodos <- V(g)$name

  expect_equal(length(nodos), length(unique(nodos)))
})

test_that("Las aristas tienen el atributo 'weight' correctamente asignado", {
  df <- make_clean_df(pesos = c(5, 2))
  g <- generate_graph(df)
  pesos_grafo <- E(g)$weight

  expect_true(!is.null(pesos_grafo))
  expect_equal(sort(pesos_grafo), c(2, 5))
})

test_that("Las aristas tienen el atributo 'type' como factor", {
  df <- make_clean_df(tipos = c("Amigo", "Enemigo"))
  g <- generate_graph(df)

  expect_true(is.factor(E(g)$type))
})

test_that("Las aristas tienen el atributo 'type' con los niveles correctos", {
  df <- make_clean_df(tipos = c("Amigo", "Enemigo"))
  g <- generate_graph(df)
  tipos_grafo <- levels(E(g)$type)

  expect_true("Amigo" %in% tipos_grafo)
  expect_true("Enemigo" %in% tipos_grafo)
})

test_that("Grafo con un solo nodo origen = destino (auto-bucle) no crashea", {
  df <- make_clean_df(
    origenes = c("Alice"),
    destinos = c("Alice"),
    tipos    = c("Auto"),
    pesos    = c(1)
  )
  # Debe poder generar el grafo sin error
  expect_no_error(generate_graph(df))
})

test_that("Grafo con una sola relación genera 1 arista y 2 nodos distintos", {
  df <- make_clean_df(
    origenes = "Alice", destinos = "Bob",
    tipos = "Amigo", pesos = 1
  )
  g <- generate_graph(df)

  expect_equal(ecount(g), 1)
  expect_equal(vcount(g), 2)
})
