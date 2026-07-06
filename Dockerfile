# Dockerfile para NexusGraph
# Imagen base oficial de Rocker: R 4.4 estable, Ubuntu 22.04, sin extras
FROM rocker/r-ver:4.4

LABEL maintainer="yeib"
LABEL description="NexusGraph: CSV/Excel a grafos interactivos OSINT"
LABEL version="0.2.0"

# ── Dependencias del sistema ──────────────────────────────────────────────────
# pandoc: requerido por visSave() para generar HTML auto-contenido
# libxml2-dev, libglpk-dev: dependencias de igraph
# libfontconfig1-dev, libfreetype6-dev: requeridos por systemfonts (ggplot2)
# libcurl4-openssl-dev: requerido por curl (usado por pak y varios paquetes)
RUN apt-get update -q && apt-get install -y --no-install-recommends \
    pandoc \
    libxml2-dev \
    libglpk-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Directorio de trabajo ─────────────────────────────────────────────────────
WORKDIR /nexusgraph

# ── Instalar paquetes R ───────────────────────────────────────────────────────
# Copiamos solo los archivos de dependencias primero para aprovechar el
# cache de capas de Docker: si el código fuente cambia pero no las deps,
# no se reinstalan los paquetes (que tardan varios minutos).
COPY install_packages.R .
RUN Rscript install_packages.R

# ── Copiar el código fuente ───────────────────────────────────────────────────
COPY . .

# Asegurarse de que el script principal sea ejecutable
RUN chmod +x nexusgraph.sh

# ── Crear directorio de salida ────────────────────────────────────────────────
RUN mkdir -p output

# ── Exponer puerto para la web UI ─────────────────────────────────────────────
EXPOSE 3838

# ── Punto de entrada ──────────────────────────────────────────────────────────
# Por defecto, arranca el modo CLI (pasando argumentos al contenedor).
# Para la web UI, usa: docker run -p 3838:3838 nexusgraph --web
ENTRYPOINT ["./nexusgraph.sh"]
