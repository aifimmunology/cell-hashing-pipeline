FROM us.gcr.io/dev-pipeline-internal/google-r-base@sha256:259f258641580f5772c953ddcdc2289c6882d3b2d40aeb77a5a7eb5242a8017e

## Resolving R and lib dependencies
RUN apt-get update \
    && apt-get install -y \
    python3.7-dev \
    build-essential \
    libbz2-dev \
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
    && python3.7 get-pip.py

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1 \
    && update-alternatives --set python /usr/bin/python3.7 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 1 \
    && update-alternatives --set python3 /usr/bin/python3.7 \
    && python3.7 -m pip install wheel \
    && python3.7 -m pip install python-levenshtein \
    && python3.7 -m pip install Cython \
    && python3.7 -m pip install pysam \
    && Rscript -e "install.packages(c('BiocManager', 'devtools', 'assertthat', 'cowplot', 'data.table', 'dplyr', 'ids', 'ggplot2', 'jsonlite', 'Matrix', 'optparse', 'purrr', 'R.utils', 'rmarkdown')); BiocManager::install('rhdf5')" \
    && python3.7 -m pip install CITE-seq-Count==1.4.3 \
    ## clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

COPY /root/.ssh /root/.ssh

## Install packages from CRAN
RUN git clone git@github.com:aifimmunology/H5weaver.git \
    && git clone git@github.com:aifimmunology/HTOparser.git \
    && git clone git@github.com:aifimmunology/cell-hashing-pipeline.git \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds /root/.ssh

ENTRYPOINT ["tail", "-f", "/dev/null"]
