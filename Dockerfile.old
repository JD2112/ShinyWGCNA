# Use Ubuntu as the base image
FROM ubuntu:20.04
LABEL   authors = "Jyotirmoy Das" \
        description = "Docker image for ShinyWGCNA"

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set environment variables
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV R_LIBS_USER=/usr/local/lib/R/site-library

# Install system dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    dirmngr \
    wget \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libssl-dev \
    libpng-dev \
    libhdf5-dev \
    libgit2-dev \
    gdebi-core \
    libgfortran5 \
    liblapack-dev \
    libblas-dev \
    libcairo2-dev \
    libxt-dev

# Add R repository
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

# Install R (this will install the latest version available in the repository)
RUN apt-get update && apt-get install -y r-base r-base-dev

# Install Shiny Server
RUN wget --no-verbose https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.17.973-amd64.deb && \
    gdebi -n shiny-server-1.5.17.973-amd64.deb && \
    rm shiny-server-1.5.17.973-amd64.deb

# Install R packages
RUN R -e "install.packages(c('shiny', 'shinydashboard', 'shinyjs', 'DT', 'plotly', 'ggplot2', 'reshape2', 'RColorBrewer', 'pheatmap', 'heatmaply', 'dplyr', 'tidyr', 'stringr', 'purrr', 'readr', 'tibble', 'magrittr'), repos='http://cran.rstudio.com/', dependencies=TRUE)"

# Install Bioconductor and required packages
RUN R -e "if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager'); BiocManager::install(c('impute', 'preprocessCore', 'GO.db', 'AnnotationDbi', 'org.Hs.eg.db', 'ComplexHeatmap'))"

# Install WGCNA and verify installation
RUN R -e "install.packages('WGCNA', repos='http://cran.rstudio.com/', dependencies=TRUE)" && \
    R -e "if (!require('WGCNA')) stop('WGCNA package not installed successfully')"

# List installed packages
RUN R -e "installed.packages()[,c('Package', 'Version')]"

# Copy the application files into the image
COPY app/ /srv/shiny-server/

# Change owner of /srv/shiny-server
RUN chown -R shiny:shiny /srv/shiny-server/
RUN chown -R shiny:shiny /var/lib/shiny-server/

# Set the working directory
WORKDIR /srv/shiny-server

# Expose the application port
EXPOSE 3838

# Run the Shiny app
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server', host = '0.0.0.0', port = 3838)"]