FROM us.gcr.io/dev-pipeline-internal/google-r-base:v1.0

## Resolving R and lib dependencies
RUN apt-get update \
    && apt-get install -y \
    python3-dev \
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
    python3-dev \
    python3-distutils \
    ## clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds


RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3 get-pip.py  --force-reinstall

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --set python /usr/bin/python3 \
    # && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 1 \
    # && update-alternatives --set python3 /usr/bin/python3.7 \
    && python3 -m pip install wheel \
    && python3 -m pip install python-levenshtein \
    && python3 -m pip install Cython \
    && python3 -m pip install pysam \
    && Rscript -e "install.packages(c('BiocManager', 'devtools', 'assertthat', 'cowplot', 'data.table', 'dplyr', 'ids', 'ggplot2', 'jsonlite', 'Matrix', 'optparse', 'purrr', 'R.utils', 'rmarkdown')); BiocManager::install('rhdf5')" \
    && python3 -m pip install CITE-seq-Count==1.4.3 \
    ## clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

COPY auth_token.enc /tmp/auth_token

## Install packages from CRAN
RUN export GITHUB_PAT=$(cat /tmp/auth_token) \
    && Rscript -e "Sys.getenv('GITHUB_PAT'); devtools::install_github(repo = 'aifimmunology/H5weaver', username = 'aifi-aldan'); devtools::install_github(repo = 'aifimmunology/HTOparser', username = 'aifi-aldan')" \
    ## clean up
    && git clone https://aifi-aldan:$GITHUB_PAT@github.com/aifimmunology/cell-hashing-pipeline.git \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds /tmp/auth_token

ENTRYPOINT ["tail", "-f", "/dev/null"]
