#!/bin/bash

echo "This script assumes the wsl container is set up for CUDA"
echo "You can download the CUDNN Package at: https://developer.nvidia.com/cudnn"
echo "Check the variables at the top of this file before running (especially CUDA_ARCH_BIN, see https://en.wikipedia.org/wiki/CUDA for the version supported by your GPU)"

# TODO: replace the CUDA_ARCH_BIN in the opencv script based on a variable here

[[ "$(read -e -p 'Continue? [y/N]> '; echo $REPLY)" == [Yy]* ]] && echo Continuing || (exit 1 && echo Stopping)


CUDA_ARCH_BIN="5.0"
cuda_version="11-2"
cudnn_file="libcudnn8.deb"
cudnn_lib_file="cudnn-11.2-linux-x64-v8.1.1.33.tgz"

echo "*** Installing Cuda toolkit"
# From here: https://docs.nvidia.com/cuda/wsl-user-guide/index.html

sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/7fa2af80.pub

sudo sh -c 'echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64 /" > /etc/apt/sources.list.d/cuda.list'

sudo apt-get update

sudo apt-get install -y cuda-toolkit-${cuda_version}

sudo cp /usr/lib/wsl/lib/nvidia-smi /usr/bin/nvidia-smi
sudo chmod ogu+x /usr/bin/nvidia-smi

echo "*** Installing CUDNN"
# From here: https://www.reddit.com/r/bashonubuntuonwindows/comments/i0lyq4/configuring_cudnn_on_wsl/

sudo dpkg -i ${cudnn_file}

# The deb doesn't do a great job it seems, copy as well: https://docs.nvidia.com/deeplearning/cudnn/install-guide/index.html#installlinux
tar -xzvf cudnn-11.2-linux-x64-v8.1.1.33.tgz

sudo cp cuda/include/cudnn*.h /usr/local/cuda/include 
sudo cp -P cuda/lib64/libcudnn* /usr/local/cuda/lib64 
sudo chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn*

echo "*** Installing miniconda 3.7"

wget https://repo.anaconda.com/miniconda/Miniconda3-py37_4.9.2-Linux-x86_64.sh
bash Miniconda3-py37_4.9.2-Linux-x86_64.sh

source ~/.bashrc

conda install numpy

echo "*** Installing Opencv"

wget https://raw.githubusercontent.com/Christophe-Foyer/install_scripts/main/opencv_install.sh

sed -ie 's/CUDA_ARCH_BIN="5.0"/CUDA_ARCH_BIN="${CUDA_ARCH_BIN}"/g' opencv_install.sh

bash opencv_install.sh

# Is this dumb to do after it alread has it installed?
#sudo apt install libopencv-dev -y

echo "*** Installing Darknet"

git clone https://github.com/AlexeyAB/darknet
cd darknet
sed -ie "s/GPU=0/GPU=1/g" Makefile
sed -ie "s/CUDNN=0/CUDNN=1/g" Makefile
sed -ie "s/OPENCV=0/OPENCV=1/g" Makefile

sed -ie "s|LDFLAGS+= -L/usr/local/cuda/lib64 -lcuda -lcudart -lcublas -lcurand|LDFLAGS+= -L/usr/local/cuda/lib64 -lcudart -lcublas -lcurand -L/usr/local/cuda/lib64/stubs -lcuda|g" Makefile

sed -ie "s|NVCC=nvcc|NVCC=/usr/local/cuda/bin/nvcc|" Makefile

make
