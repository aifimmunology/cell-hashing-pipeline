FROM us.gcr.io/dev-pipeline-internal/google-r-base:v2.0

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys KEYS-HERE

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    apt-utils \
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
    liblapack-dev \
    liblapack3 \
    libopenblas-base \
    libopenblas-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype-dev \
    libtiff5-dev \
    libjpeg-dev \
    git \
    ## clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

RUN export R_HOME=/usr/lib/R

RUN R -e 'install.packages("devtools")'
RUN R -e 'install.packages("optparse")'
RUN R -e 'install.packages("jsonlite")'
RUN R -e 'install.packages("rmarkdown")'
RUN R -e 'install.packages("cowplot")'

RUN R -e 'install.packages("BiocManager");BiocManager::install()'
RUN R -e 'BiocManager::install(c("rhdf5", "GenomicRanges"))'
RUN R -e 'devtools::install_github("aifimmunology/H5weaver"; devtools::install_github("aifimmunology/HTOparser"' \
    && git clone -b master https://github.com/aifimmunology/cell-hashing-pipeline.git \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds