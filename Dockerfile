FROM us.gcr.io/dev-pipeline-internal/google-r-base:v2.0

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys KEYS-HERE

## Resolving R and lib dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    # build-essential \
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

RUN export R_HOME=/usr/lib/R
RUN R -e 'install.packages("devtools")'
RUN R -e 'install.packages("optparse")'
RUN R -e 'install.packages("jsonlite")'
RUN R -e 'install.packages("rmarkdown")'

## Install packages from github
COPY auth_token /tmp/auth_token
RUN export GITHUB_PAT=$(cat /tmp/auth_token) \
    && R -e 'devtools::install_github("aifimmunology/H5weaver", auth_token = Sys.getenv("GITHUB_PAT")); devtools::install_github("aifimmunology/HTOparser", auth_token = Sys.getenv("GITHUB_PAT"))' \
    && git clone -b master https://aifi-gitops:$GITHUB_PAT@github.com/aifimmunology/cell-hashing-pipeline.git \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds /tmp/auth_token