FROM us.gcr.io/dev-i-collabcloud/google-r-base@sha256:fc0f941fc133fc049f7df3150c2fe0b698ce9dbc04432000c730ce2f6cd90a3b

## Resolving R and lib dependencies
RUN apt-get update \
    && apt-get install -y \
    python3-pip \
    libbz2-dev \
    liblzma-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libhdf5-dev \
    pandoc \
    && pip3 install Cython \
    && Rscript -e "install.packages(c('BiocManager', 'devtools', 'assertthat', 'cowplot', 'data.table', 'dplyr', 'ids', 'ggplot2', 'jsonlite', 'Matrix', 'optparse', 'purrr', 'R.utils', 'rmarkdown')); BiocManager::install('rhdf5')" \
    && pip3 install CITE-seq-Count==1.4.3 \
    ## clean up
    && apt-get clean \ 
    && rm -rf /var/lib/apt/lists/ \ 
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds
    
## Install packages from Github
RUN Rscript -e "devtools::install_github(repo = 'aifimmunology/H5weaver', username = 'aifi-aldan', auth_token = '***TOKEN***')" \
    && Rscript -e "devtools::install_github(repo = 'aifimmunology/HTOparser', username = 'aifi-aldan', auth_token = '***TOKEN***')" \
    ## clean up
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && git clone https://aifi-aldan:***TOKEN***@github.com/aifimmunology/cell-hashing-pipeline.git 

ENTRYPOINT ["tail", "-f", "/dev/null"]
