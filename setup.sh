#!/bin/bash

set -eu

BASE_DIR=$PWD

mkdir -p toolchains emulators

# install gnu toolchain for building test ELFs if not present
if [ ! -d "toolchains/risc0-riscv32im" ]; then
    echo "Downloading and installing RISC0 toolchain..."
    curl -L https://github.com/risc0/toolchain/releases/download/2024.01.05/riscv32im-linux-x86_64.tar.xz | tar -xJ -C toolchains/
    mv toolchains/riscv32im-linux-x86_64 toolchains/risc0-riscv32im
else
    echo "RISC0 toolchain already installed, skipping..."
fi

# golden model risc-v simulator
if [ ! -d "emulators/sail-riscv" ]; then
    echo "Downloading and installing Sail model..."
    curl -L https://github.com/riscv/sail-riscv/releases/download/0.7/sail_riscv-Linux-x86_64.tar.gz | tar -xz -C emulators/
    mv emulators/sail_riscv-Linux-x86_64 emulators/sail-riscv
else
    echo "Sail model already exists, skipping..."
fi


# building risc0 (risc-v isa simulator)
if [ ! -d "emulators/risc0" ]; then
    echo "Cloning and building RISC0 emulator..."  
    git clone -b cg/riscof https://github.com/codygunton/risc0.git emulators/risc0
    cd emulators/risc0
    mkdir -p build
    cargo build -p risc0-r0vm
    cd $BASE_DIR
else
    echo "RISC0 emulator already exists, skipping build..."
fi

# set up python environment
if [ ! -d ".venv" ]; then
    echo "Setting up Python virtual environment..."
    python3 -m venv .venv
    source .venv/bin/activate
    python3 -m pip install -r requirements.txt
else
    echo "Python virtual environment already exists, activating..."
    source .venv/bin/activate
fi

# setting up riscof testing framework with plugins
if [ ! -d "riscv-arch-test" ]; then
    # Clone arch-test repository; pinning a version, but others may work too
    riscof arch-test --clone --get-version 3.9.1
else
    echo "RISCOF framework already set up, skipping..."
fi

echo "Setup completed. Use './run.sh' to test the Spike simulator against the Sail reference model."
