FROM us.gcr.io/dev-pipeline-internal/google-r-base:v1.0

## Resolving R and lib dependencies
RUN apt-get update \
    && apt-get install -y \
    build-essential \
    libbz2-dev \
    libc6-dev \
    libgcc-9-dev \
    gcc-9-base \
    liblzma-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libhdf5-dev \
    pandoc \
    libpng-dev \
    pkg-config \
    ## clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

## Install packages from CRAN & BioConductor
RUN Rscript -e "install.packages(c('BiocManager', 'devtools', 'assertthat', 'cowplot', 'data.table', 'dplyr', 'ids', 'ggplot2', 'jsonlite', 'Matrix', 'optparse', 'purrr', 'R.utils', 'rmarkdown')); BiocManager::install(c('rhdf5', 'SingleCellExperiment', 'SummarizedExperiment'))" \
    ## clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

## Install packages from github
COPY auth_token /tmp/auth_token
RUN export GITHUB_PAT=$(cat /tmp/auth_token) \
    && Rscript -e "devtools::install_github(repo = 'aifimmunology/H5weaver', auth_token = Sys.getenv('GITHUB_PAT')); devtools::install_github(repo = 'aifimmunology/HTOparser', auth_token = Sys.getenv('GITHUB_PAT'))" \
    ## clean up
    && git clone https://aifi-gitops:$GITHUB_PAT@github.com/aifimmunology/cell-hashing-pipeline.git \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds /tmp/auth_token
