#!/bin/bash

set -eu

BASE_DIR=$PWD

mkdir -p toolchains emulators plugins

if [ ! -d "toolchains/risc0-riscv32im" ]; then
    curl -L https://github.com/risc0/toolchain/releases/download/2024.01.05/riscv32im-linux-x86_64.tar.xz -o riscv-gnu-toolchain.tar.xz
    tar xf riscv-gnu-toolchain.tar.xz
    mv riscv32im-linux-x86_64 toolchains/risc0-riscv32im
    rm -rf riscv-gnu-toolchain.tar.xz
else
    echo "RISC0 toolchain already installed, skipping..."
fi

export PATH=$PWD/toolchains/risc0-riscv32im/bin:$PATH

# sail formal specification language, used to define the "golden model"
if [ ! -d "toolchains/sail-lang" ]; then
    echo "Downloading and installing Sail language..."
    curl -L https://github.com/rems-project/sail/releases/download/0.19-linux-binary/sail.tar.gz -o sail.tar.gz
    tar -xzf sail.tar.gz
    mkdir -p toolchains/sail-lang
    mv sail/* toolchains/sail-lang/
    rmdir sail
    rm sail.tar.gz
else
    echo "Sail language already installed, skipping..."
fi

export PATH=$PATH:$BASE_DIR/toolchains/sail-lang/bin

# golden model risc-v simulator
if [ ! -d "emulators/sail-riscv" ]; then
    echo "Cloning and building Sail RISC-V reference model..."
    git clone --revision 03ceb5ba24e88c82a0bbe0c776afb8702057e81a https://github.com/riscv/sail-riscv.git emulators/sail-riscv
    cd emulators/sail-riscv
    export DOWNLOAD_GMP=OFF
    ./build_simulators.sh
    cd build/c_emulator/
    ln -sf riscv_sim_rv32d riscv_sim_RV32
    ln -sf riscv_sim_rv64d riscv_sim_RV64
    cd $BASE_DIR
else
    echo "RISC-V reference model already exists, skipping build..."
    # Ensure symlinks are created even if we skip the build
    if [ -d "emulators/sail-riscv/build/c_emulator" ]; then
        cd emulators/sail-riscv/build/c_emulator/
        ln -sf riscv_sim_rv32d riscv_sim_RV32
        ln -sf riscv_sim_rv64d riscv_sim_RV64
        cd $BASE_DIR
    fi
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

# put r0vm in path
export PATH=$PATH:$BASE_DIR/emulators/risc0/target/debug

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
if [ ! -d "plugins/risc0" ] || [ ! -d "plugins/sail_cSim" ]; then
    echo "Setting up RISCOF framework with plugins..."
    
    # Setup plugins directory
    mkdir -p plugins
    
    # Initialize plugins
    riscof setup --dutname=risc0
    
    # Move plugins to the correct location if they're not there already
    if [ -d "risc0" ] && [ ! -d "plugins/risc0" ]; then
        mv risc0 plugins/
    fi
    
    if [ -d "sail_cSim" ] && [ ! -d "plugins/sail_cSim" ]; then
        mv sail_cSim plugins/
    fi
    
    # Clone arch-test repository
    riscof arch-test --clone

    # # Remove PMP section from spike_isa.yaml using Python's yq module
    # echo "Modifying YAML file to remove PMP section..."
    # python3 -m yq 'del(.hart0.PMP)' -y -i plugins/risc0/risc0_isa.yaml
else
    echo "RISCOF framework already set up, skipping..."
fi

# # Update config.ini with correct paths using our Python script
# echo "Updating config.ini with correct paths..."
# python3 update_config.py

echo "Setup completed. Use './run.sh' to test the Spike simulator against the Sail reference model."
echo "Note: YOU MUST UPDATE THE SIGNATURE GRANULARITY TO 4; SEE THE README."