# #!/bin/bash

# set -eu

# BASE_DIR=$PWD

# # installing system dependencies if on ubuntu
# if [ -f /etc/os-release ] && grep -q "Ubuntu" /etc/os-release; then
#     sudo apt install build-essential \
#         libgmp-dev \
#         z3 \
#         pkg-config \
#         zlib1g-dev \
#         cmake \
#         curl \
#         texinfo \
#         autoconf \
#         automake \
#         autotools-dev \
#         python3 \
#         libmpc-dev \
#         libmpfr-dev \
#         gawk \
#         bison \
#         flex \
#         gperf \
#         libtool \
#         patchutils \
#         bc \
#         libexpat-dev \
#         device-tree-compiler # may be called dtc in some distros
# fi

# # set up risc-v gnu toolchain
# curl -L https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2025.01.20/riscv32-elf-ubuntu-24.04-gcc-nightly-2025.01.20-nightly.tar.xz -o riscv-gnu-toolchain.tar.xz
# tar -xf riscv-gnu-toolchain.tar.xz
# mv riscv riscv-gnu-toolchain
# rm riscv-gnu-toolchain.tar.xz

# # installing sail formal specification language to build sail-riscv
# curl -L https://github.com/rems-project/sail/releases/download/0.19-linux-binary/sail.tar.gz -o sail.tar.gz
# tar -xzf sail.tar.gz
# rm sail.tar.gz
# export PATH=$PATH:$BASE_DIR/sail/bin

# # # building sail risc-v simulator
# # git clone --revision 03ceb5ba24e88c82a0bbe0c776afb8702057e81a https://github.com/riscv/sail-riscv.git
# cd sail-riscv
# ./build_simulators.sh
# cd build/c_emulator/ || { echo "Error: build/c_emulator directory does not exist"; exit 1; }
# ln -s riscv_sim_rv32d riscv_sim_RV32
# ln -s riscv_sim_rv64d riscv_sim_RV64
# cd $BASE_DIR

# # building spike (risc-v isa simulator)
# git clone https://github.com/riscv-software-src/riscv-isa-sim.git
# cd riscv-isa-sim
# mkdir build
# cd build
# ../configure --prefix=/path/to/install
# jobs=$( (nproc || sysctl -n hw.ncpu || echo 2) 2>/dev/null)
# make -j${jobs}
# cd $BASE_DIR

# set up python environment
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt

# setting up riscof testing framework
riscof setup --dutname=spike
riscof arch-test --clone

# Remove PMP section from spike_isa.yaml using Python's yq module
echo "Modifying YAML file to remove PMP section (IOU fixing version mismatch?)..."
python3 -m yq 'del(.hart0.PMP)' -y -i spike/spike_isa.yaml

# Make run.sh executable
chmod +x run.sh

echo "Setup completed. Use './run.sh' to run the tests."