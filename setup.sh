#!/bin/bash
BASE_DIR=$PWD

# installing system dependencies
sudo apt install build-essential \
    libgmp-dev \
    z3 \
    pkg-config \
    zlib1g-dev \
    cmake \
    curl \
    texinfo \
    autoconf \
    automake \
    autotools-dev \
    python3 \
    libmpc-dev \
    libmpfr-dev \
    gawk \
    bison \
    flex \
    gperf \
    libtool \
    patchutils \
    bc \
    libexpat-dev \
    device-tree-compiler

# setting up risc-v gnu toolchain
curl -L https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2025.01.20/riscv32-elf-ubuntu-24.04-gcc-nightly-2025.01.20-nightly.tar.xz -o riscv-gnu-toolchain.tar.xz
tar -xf riscv-gnu-toolchain.tar.xz
mv riscv riscv-gnu-toolchain
rm riscv-gnu-toolchain.tar.xz
PATH=$PATH:$PWD/riscv-gnu-toolchain/bin/

# installing sail formal specification language
curl -L https://github.com/rems-project/sail/releases/download/0.19-linux-binary/sail.tar.gz -o sail.tar.gz
tar -xzf sail.tar.gz
rm sail.tar.gz
export PATH=$PATH:$PWD/sail/bin

# building sail risc-v simulator
git clone https://github.com/riscv/sail-riscv.git
cd sail-riscv
./build_simulators.sh
# creating symlinks for sail simulator
cd build/c_emulator/
ln -s riscv_sim_rv32d riscv_sim_RV32
PATH=$PATH:$PWD
cd $BASE_DIR

# building spike (risc-v isa simulator)
git clone https://github.com/riscv-software-src/riscv-isa-sim.git
cd riscv-isa-sim
mkdir build
cd build
../configure --prefix=/path/to/install
make -j
PATH=$PATH:$PWD/build
cd $BASE_DIR

# setting up python environment and riscof
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt

# setting up riscof testing framework
riscof setup --dutname=spike
riscof arch-test --clone
riscof validateyaml --config=config.ini
riscof testlist --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env

# running riscof tests
riscof run --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env