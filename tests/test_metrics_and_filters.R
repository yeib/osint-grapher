# tests/test_metrics_and_filters.R
# Tests unitarios para las nuevas funciones de NexusGraph:
# - Filtros de load_and_clean_data (min_peso, tipos)
# - generate_graph(directed = FALSE)
# - compute_network_metrics()
# - print_top_nodes()

library(testthat)
library(dplyr)
library(igraph)

root <- Sys.getenv("NEXUSGRAPH_ROOT", unset = getwd())
source(file.path(root, "R", "process_data.R"))

# =============================================================================
# Helper
# =============================================================================
make_temp_csv <- function(content) {
  path <- tempfile(fileext = ".csv")
  writeLines(content, path)
  return(path)
}

make_clean_df <- function(
    origenes  = c("Alice", "Bob", "Carol"),
    destinos  = c("Bob",   "Carol", "Alice"),
    tipos     = c("Amigo", "Colega", "Amigo"),
    pesos     = c(3, 2, 1)
) {
  data.frame(
    Origen        = origenes,
    Destino       = destinos,
    Tipo_Relacion = tipos,
    Peso          = pesos,
    stringsAsFactors = FALSE
  )
}

# =============================================================================
# Tests: Filtros en load_and_clean_data
# =============================================================================

test_that("Filtro min_peso elimina relaciones por debajo del umbral", {
  csv <- make_temp_csv(
    "Origen,Destino,Tipo_Relacion,Peso\nAlice,Bob,Amigo,5\nBob,Carol,Colega,1\nCarol,Dave,Rival,3"
  )
  df <- load_and_clean_data(csv, min_peso = 3)

  # Peso 1 debe quedar fuera
  expect_false(any(df$Peso < 3))
  expect_equal(nrow(df), 2)
})

test_that("Filtro min_peso = 0 no elimina nada", {
  csv <- make_temp_csv(
    "Origen,Destino,Tipo_Relacion,Peso\nAlice,Bob,Amigo,1\nBob,Carol,Colega,0"
  )
  df <- load_and_clean_data(csv, min_peso = 0)
  expect_equal(nrow(df), 2)
})

test_that("Filtro tipos incluye solo los tipos especificados", {
  csv <- make_temp_csv(
    "Origen,Destino,Tipo_Relacion\nAlice,Bob,Amigo\nBob,Carol,Enemigo\nCarol,Dave,Amigo"
  )
  df <- load_and_clean_data(csv, tipos = c("Amigo"))

  expect_true(all(df$Tipo_Relacion == "Amigo"))
  expect_equal(nrow(df), 2)
})

test_that("Filtro tipos vacío (NULL) no filtra nada", {
  csv <- make_temp_csv(
    "Origen,Destino,Tipo_Relacion\nAlice,Bob,Amigo\nBob,Carol,Enemigo"
  )
  df <- load_and_clean_data(csv, tipos = NULL)
  expect_equal(nrow(df), 2)
})

test_that("Combinación de filtros min_peso + tipos funciona", {
  csv <- make_temp_csv(
    "Origen,Destino,Tipo_Relacion,Peso\nAlice,Bob,Amigo,5\nBob,Carol,Enemigo,1\nCarol,Dave,Amigo,2"
  )
  df <- load_and_clean_data(csv, min_peso = 3, tipos = c("Amigo"))

  # Solo Alice->Bob (Amigo, Peso=5) pasa los dos filtros
  expect_equal(nrow(df), 1)
  expect_equal(df$Origen[1], "Alice")
})

# =============================================================================
# Tests: generate_graph(directed = FALSE)
# =============================================================================

test_that("generate_graph con directed=FALSE devuelve grafo no dirigido", {
  df <- make_clean_df()
  g <- generate_graph(df, directed = FALSE)

  expect_false(is_directed(g))
})

test_that("generate_graph con directed=TRUE (default) devuelve grafo dirigido", {
  df <- make_clean_df()
  g <- generate_graph(df)

  expect_true(is_directed(g))
})

# =============================================================================
# Tests: compute_network_metrics()
# =============================================================================

test_that("compute_network_metrics agrega atributo degree a los nodos", {
  df <- make_clean_df()
  g <- generate_graph(df) %>% compute_network_metrics()

  expect_false(is.null(V(g)$degree))
  expect_true(all(V(g)$degree >= 0))
})

test_that("compute_network_metrics agrega atributo betweenness a los nodos", {
  df <- make_clean_df()
  g <- generate_graph(df) %>% compute_network_metrics()

  expect_false(is.null(V(g)$betweenness))
  expect_true(all(V(g)$betweenness >= 0))
})

test_that("compute_network_metrics agrega atributo group a los nodos", {
  df <- make_clean_df()
  g <- generate_graph(df) %>% compute_network_metrics()

  expect_false(is.null(V(g)$group))
  expect_true(all(V(g)$group >= 1))
})

test_that("compute_network_metrics agrega atributo community con prefijo 'Comunidad'", {
  df <- make_clean_df()
  g <- generate_graph(df) %>% compute_network_metrics()

  expect_true(all(grepl("^Comunidad", V(g)$community)))
})

test_that("compute_network_metrics funciona con grafo de 1 solo nodo (auto-bucle)", {
  df <- make_clean_df(
    origenes = "Alice", destinos = "Alice",
    tipos = "Auto", pesos = 1
  )
  g <- generate_graph(df)
  # No debe crashear
  expect_no_error(compute_network_metrics(g))
  g_m <- compute_network_metrics(g)
  expect_equal(V(g_m)$group, 1L)
})

# =============================================================================
# Tests: print_top_nodes()
# =============================================================================

test_that("print_top_nodes no crashea con un grafo normal con métricas", {
  df <- make_clean_df()
  g <- generate_graph(df) %>% compute_network_metrics()

  # Capturamos la salida de cat() para evitar ruido en la consola de tests
  expect_no_error(
    capture.output(print_top_nodes(g))
  )
})

test_that("print_top_nodes avisa si el grafo no tiene métricas calculadas", {
  df <- make_clean_df()
  g <- generate_graph(df)
  # Sin compute_network_metrics, V(g)$degree es NULL

  salida <- capture.output(print_top_nodes(g))
  expect_true(any(grepl("Métricas no calculadas", salida)))
})
