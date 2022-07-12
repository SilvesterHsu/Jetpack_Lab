FROM nvidia/cuda:10.2-cudnn8-devel-ubuntu18.04

ENV DEBIAN_FRONTEND noninteractive

ADD conda_env /opt/conda_env

RUN rm /etc/apt/sources.list.d/nvidia-ml.list && apt-get clean && apt-get update
RUN apt update && \
    apt install build-essential \
    wget \
    libgl1 \
    libglib2.0-0 \
    wget -y && \
    rm -rf /var/lib/apt/lists/*

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    /opt/conda/bin/conda env create -f /opt/conda_env/bev.yaml && \
    /opt/conda/bin/conda init bash && \
    echo "conda deactivate" >> /root/.bashrc

ENV PATH /opt/conda/bin:/usr/local/cuda/bin:/usr/local/bin:$PATH
ENV LD_LIBRARY_PATH /usr/local/lib:/usr/local/cuda/lib64
ENV LIBRARY_PATH /usr/local/cuda/lib64:/usr/local/cuda/lib64/stubs:/usr/local/lib
ENV C_INCLUDE_PATH /usr/include/x86_64-linux-gnu:/usr/local/include:/usr/local/cuda/include:/usr/local/include/opencv4:/usr/local/include/eigen3
ENV CPLUS_INCLUDE_PATH /usr/include/x86_64-linux-gnu:/usr/local/include:/usr/local/cuda/include:/usr/local/include/opencv4:/usr/local/include/eigen3

CMD ["/bin/bash"]
