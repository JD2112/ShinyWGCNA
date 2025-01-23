# Base image
FROM rocker/shiny:4.4.1

# Set labels
LABEL authors="Jyotirmoy Das" \
      description="Docker image for ShinyWGCNA"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libmagick++-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    cmake \
    gcc \
    g++ \
    make \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables to disable -Werror=format-security
ENV CFLAGS="-g -O2 -Wformat -Wno-error=format-security"
ENV CXXFLAGS="-g -O2 -Wformat -Wno-error=format-security"
ENV PKG_CFLAGS="-Wno-error=format-security"
ENV PKG_CXXFLAGS="-Wno-error=format-security"

# Install BiocManager and core Bioconductor packages
RUN R -e "install.packages('BiocManager', repos='http://cran.rstudio.com/')" && \
    R -e "Sys.setenv(MAKEFLAGS='-j4'); \
          options(warn = 2); \
          BiocManager::install(c('S4Vectors', 'IRanges', 'XVector'), \
          version = '3.20', \
          configure.args = c('--disable-warnings-as-errors', '--no-staged-install'), \
          update = TRUE, ask = FALSE)"

# Install and configure renv
RUN Rscript -e 'install.packages("renv", repos="http://cran.rstudio.com/")'
COPY renv.lock /srv/shiny-server/renv.lock
WORKDIR /srv/shiny-server
RUN Rscript -e 'renv::restore()'

# Copy Shiny app files
COPY app/ /srv/shiny-server/

# Create necessary directories and set permissions
RUN mkdir -p /srv/shiny-server/app_cache && \
    chown -R shiny:shiny /srv/shiny-server && \
    chmod -R 755 /srv/shiny-server

# Switch to the shiny user
USER shiny

# Expose port 3838 for the Shiny app
EXPOSE 3838

# Run the Shiny app
CMD ["/usr/bin/shiny-server"]