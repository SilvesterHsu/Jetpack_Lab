FROM nvidia/cuda:10.2-cudnn8-devel-ubuntu18.04 as build

ENV DEBIAN_FRONTEND noninteractive

# Protobuf
ENV PROTOBUF 3.7.0
ENV PROTOBUF_URL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF}/protobuf-all-${PROTOBUF}.zip

RUN apt update \
    && apt install autoconf automake libtool curl wget make cmake g++ unzip -y \
    && rm -rf /var/lib/apt/lists/* \
    && wget "${PROTOBUF_URL}" -O protobuf.zip \
    && unzip protobuf.zip \
    && cd protobuf* \
    && ./autogen.sh \
    && ./configure \
    && make -j 2 \
    && make install \
    && ldconfig

# Gtest
ENV GTEST 1.10.0
ENV GTEST_URL https://github.com/google/googletest/archive/refs/tags/release-${GTEST}.zip

RUN wget "${GTEST_URL}" -O gtest.zip \
    && unzip gtest.zip \
    && cd googletest* \
    && cmake -DBUILD_SHARED_LIBS=ON . \
    && make -j 2 \
    && cp -rf googletest/include/gtest /usr/local/include \
    && cp lib/* /usr/local/lib

# OpenCV
ENV OPENCV 4.1.2
ENV OPENCV_URL https://github.com/opencv/opencv/archive/refs/tags/${OPENCV}.zip

RUN cd /opt && \
    wget "${OPENCV_URL}" -O opencv.zip && \
    unzip opencv.zip && \
    mkdir -p opencv-${OPENCV}/build && cd opencv-${OPENCV}/build && \
    cmake  .. && \
    cmake --build . -- -j 2 && \
    make install

# Eigen
ENV EIGEN 3.3.9
ENV EIGEN_URL https://gitlab.com/libeigen/eigen/-/archive/${EIGEN}/eigen-${EIGEN}.zip

RUN cd /opt && \
    wget "${EIGEN_URL}" -O eigen-${EIGEN}.zip && \
    unzip eigen-${EIGEN}.zip && \
    mkdir -p eigen-${EIGEN}/build && cd eigen-${EIGEN}/build && \
    cmake .. && \
    make install 

FROM nvidia/cuda:10.2-cudnn8-devel-ubuntu18.04

ENV DEBIAN_FRONTEND noninteractive

COPY --from=build /usr/local/include /usr/local/include
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /usr/local/bin /usr/local/bin

ADD third_party /opt/third_party

# TensorRT
ENV TENSORRT_VERSION cuda10.2-trt7.1.3.4-ga-20200617
ENV TENSORRT_URL http://jupi.ink:83/ubuntu/cuda/nv-tensorrt-repo-ubuntu1804-${TENSORRT_VERSION}_1-1_amd64.deb

RUN apt update \
    && apt install curl -y \
    && rm -rf /var/lib/apt/lists/* \
    && curl "${TENSORRT_URL}" -o tensorrt.deb \
    && dpkg -i tensorrt.deb \
    && apt-key add /var/nv-tensorrt-repo-${TENSORRT_VERSION}/7fa2af80.pub \
    && apt update \
    && rm -rf /var/lib/apt/lists/*nvidia* \
    && apt install -y tensorrt \
    && rm -f tensorrt.deb \
    && rm -rf /var/lib/apt/lists/*

RUN apt update && \
    apt install -y --no-install-recommends --allow-unauthenticated \
    git scons python2.7 ninja-build cmake g++ wget curl unzip -y && \
    rm -rf /var/lib/apt/lists/* && \
    curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py && \
    python2 get-pip.py && \
    pip install cpplint && \
    bash /opt/third_party/blade/install

# Set pytorch to 1.5.0 for cuda 10.2
ENV TORCH_VERSION 1.5.0
ENV TORCHVISION_VERSION 0.6.0

RUN apt update \
    && apt install -y vim curl python3 python3-pip libboost-filesystem-dev \
    && pip3 install --upgrade pip \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir torch==${TORCH_VERSION} \
    torchvision==${TORCHVISION_VERSION}

ENV PATH /usr/local/cuda/bin:/usr/local/bin:$PATH
ENV LD_LIBRARY_PATH /usr/local/lib:/usr/local/cuda/lib64
ENV LIBRARY_PATH /usr/local/cuda/lib64:/usr/local/cuda/lib64/stubs:/usr/local/lib
ENV C_INCLUDE_PATH /usr/include/x86_64-linux-gnu:/usr/local/include:/usr/local/cuda/include:/usr/local/include/opencv4:/usr/local/include/eigen3
ENV CPLUS_INCLUDE_PATH /usr/include/x86_64-linux-gnu:/usr/local/include:/usr/local/cuda/include:/usr/local/include/opencv4:/usr/local/include/eigen3

CMD ["/bin/bash"]
