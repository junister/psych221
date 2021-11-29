
# Dockerize Vistalab's pbrt-v4 for GPU.

FROM nvidia/cuda:11.4.1-devel-ubuntu20.04

MAINTAINER Zhenyi Liu <zhenyiliu@stanford.edu>
# Updated with debug tools & optix libs by David Cardinal

ENV DEBIAN_FRONTEND=noninteractive

# Install a higher version of cmake
RUN apt-get update -yq && \
apt-get install -yq software-properties-common && \
add-apt-repository ppa:graphics-drivers && \
add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
apt-get update


# add bash so we can work interactively for debugging
RUN apt-get install -yq bash vim

RUN apt-get update -yq && apt-get install -yq --no-install-recommends \
	build-essential \
	gcc-7 \
	g++-7 \
	make \
	bison \
	flex \
	libpthread-stubs0-dev \
	zlib1g-dev \
	libgsl-dev \
	libssl-dev \
	doxygen \
	wget \
       apt-utils \
       ca-certificates \
       curl && \
    rm -rf /var/lib/apt/lists/*

# EXPERIMENTAL!!
# Copy Nvidia libraries so the runtime system doesn't need them
#COPY libs/libnvoptix.so.1 /usr/lib/x86_64-linux-gnu/libnvoptix.so.1
#COPY libs/libnvoptix.so.470.57.02 /usr/lib/x86_64-linux-gnu/libnvoptix.so.470.57.02
#COPY libs/libnvidia-rtcore.so.470.57.02 /usr/lib/x86_64-linux-gnu/libnvidia-rtcore.so.470.57.02
#COPY libs/libcuda.so.470.57.02 /usr/lib/x86_64-linux-gnu/libcuda.so.470.57.02
#COPY libs/libcuda.so.1 /usr/lib/x86_64-linux-gnu/libcuda.so.1

# Update cmake
RUN apt-get purge cmake -y && apt autoremove -y \
&& wget https://cmake.org/files/v3.18/cmake-3.18.1.tar.gz \
&& tar -xzvf cmake-3.18.1.tar.gz \
&& cd cmake-3.18.1 \
&& ./bootstrap \
&& make -j4 \
&& make install


# Setup folder structure
RUN mkdir /pbrt
WORKDIR /pbrt/

# get optiX
COPY NVIDIA-OptiX-SDK-7.2.0-linux64-x86_64 /pbrt/NVIDIA-OptiX-SDK-7.2.0-linux64-x86_64

# Pull the git directory
RUN apt-get update -yq && apt-get install -y git \
&& git clone -b omni --recursive https://github.com/scienstanford/pbrt-v4.git \
&& git clone https://github.com/Zhenyi-Liu/assimp.git \
&& cd assimp \
&& mkdir build \
&& cd build \
&& cmake .. \
&& make \
&& make install

WORKDIR /pbrt/pbrt-v4/build
RUN cmake -DCMAKE_BUILD_TYPE=MINSIZEREL -DPBRT_OPTIX7_PATH=/pbrt/NVIDIA-OptiX-SDK-7.2.0-linux64-x86_64/ .. \
&& make -j8

ENV PATH $PATH:/pbrt/pbrt-v4/build

