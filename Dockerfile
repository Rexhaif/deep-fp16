# ==================================================================
# module list
# ------------------------------------------------------------------
# python        3.7    (apt)
# pytorch       latest (pip)
# tensorflow    latest (pip)
# keras         latest (pip)
# opencv        4.1.2  (git)
# sonnet        latest (pip)
# caffe         latest (git)
# ==================================================================

FROM nvcr.io/nvidia/pytorch:19.10-py3
ENV LANG C.UTF-8
RUN APT_INSTALL="apt-get install -y --no-install-recommends" && \
    PIP_INSTALL="python -m pip --no-cache-dir install --upgrade" && \
    GIT_CLONE="git clone --depth 10" && \

    rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list && \

    apt-get update && \

# ==================================================================
# tools
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        build-essential \
        apt-utils \
        ca-certificates \
        wget \
        git \
        vim \
        libssl-dev \
        curl \
        unzip \
        unrar \
        && \

    $GIT_CLONE https://github.com/Kitware/CMake ~/cmake && \
    cd ~/cmake && \
    ./bootstrap && \
    make -j"$(nproc)" install && \

# ==================================================================
# python
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        software-properties-common \
        && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        python3.7 \
        python3.7-dev \
        python3-distutils-extra \
        && \
    wget -O ~/get-pip.py \
        https://bootstrap.pypa.io/get-pip.py && \
    python3.7 ~/get-pip.py && \
    ln -s /usr/bin/python3.7 /usr/local/bin/python3 && \
    ln -s /usr/bin/python3.7 /usr/local/bin/python && \
    $PIP_INSTALL \
        setuptools \
        && \
    $PIP_INSTALL \
        numpy \
        scipy \
        pandas \
        cloudpickle \
        scikit-learn \
        matplotlib \
        Cython \
	setuptools>=41.0.0 \
        && \

# ==================================================================
# boost
# ------------------------------------------------------------------

    wget -O ~/boost.tar.gz https://dl.bintray.com/boostorg/release/1.69.0/source/boost_1_69_0.tar.gz && \
    tar -zxf ~/boost.tar.gz -C ~ && \
    cd ~/boost_* && \
    ./bootstrap.sh --with-python=python3.7 && \
    ./b2 install -j"$(nproc)" --prefix=/usr/local && \

# ==================================================================
# fix for tf
# ------------------------------------------------------------------

    pip install wrapt --upgrade --ignore-installed && \

# ==================================================================
# tensorflow
# ------------------------------------------------------------------

    $PIP_INSTALL \
        tensorflow-gpu \
        && \

# ==================================================================
# keras
# ------------------------------------------------------------------

    $PIP_INSTALL \
        h5py \
        keras \
        && \

# ==================================================================
# opencv
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        libatlas-base-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-serial-dev \
        libleveldb-dev \
        liblmdb-dev \
        libprotobuf-dev \
        libsnappy-dev \
        protobuf-compiler \
        && \

    $GIT_CLONE --branch 4.1.2 https://github.com/opencv/opencv ~/opencv && \
    mkdir -p ~/opencv/build && cd ~/opencv/build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D WITH_IPP=OFF \
          -D WITH_CUDA=OFF \
          -D WITH_OPENCL=OFF \
          -D BUILD_TESTS=OFF \
          -D BUILD_PERF_TESTS=OFF \
          -D BUILD_DOCS=OFF \
          -D BUILD_EXAMPLES=OFF \
          .. && \
    make -j"$(nproc)" install && \
    ln -s /usr/local/include/opencv4/opencv2 /usr/local/include/opencv2 && \

# ==================================================================
# sonnet
# ------------------------------------------------------------------

    $PIP_INSTALL \
        tensorflow_probability \
        dm-sonnet \
        && \

# ==================================================================
# caffe
# ------------------------------------------------------------------

    apt-get update && \
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        caffe-cuda \
        && \
# ==================================================================
# config & cleanup
# ------------------------------------------------------------------

    ldconfig && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*
# ==================================================================
# Installing APEX
# ------------------------------------------------------------------

WORKDIR /tmp/apex-dir
RUN pip uninstall -y apex || :
RUN pip uninstall -y apex || :
RUN SHA=ToUcHmE git clone https://github.com/NVIDIA/apex.git
WORKDIR /tmp/apex-dir/apex
RUN pip install -v --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" .
WORKDIR /workspace
# ------------------------------------------------------------------
# Jupyter stuff
# ------------------------------------------------------------------
RUN pip install jupyterlab
RUN jupyter notebook --generate-config
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager
RUN echo "c.NotebookApp.password = 'sha1:ba63e3d5f01d:4e50e54ee752ab2b0b7e7bc3ae2891b0ee8933c7'" > /root/.jupyter/jupyter_notebook_config.py
# ------------------------------------------------------------------
# Two folders, probably for different storages
# ------------------------------------------------------------------
RUN mkdir /workspace/notebooks && mkdir /workspace/data

RUN conda install -y nodejs

EXPOSE 6006 8888

CMD jupyter notebook --no-browser --ip=0.0.0.0 --port=8888 --allow-root --notebook-dir='/workspace'
