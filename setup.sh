#!/bin/bash

set -eu

BASE_DIR=$PWD

mkdir -p toolchains emulators plugins

# set up risc-v gnu toolchain
if [ ! -d "toolchains/gcc-riscv" ]; then
    echo "Downloading and installing RISC-V GNU toolchain..."
    curl -L https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2025.01.20/riscv32-elf-ubuntu-24.04-gcc-nightly-2025.01.20-nightly.tar.xz -o riscv-gnu-toolchain.tar.xz
    tar -xf riscv-gnu-toolchain.tar.xz
    mkdir -p toolchains/gcc-riscv
    mv riscv/* toolchains/gcc-riscv/
    rmdir riscv
    rm riscv-gnu-toolchain.tar.xz
else
    echo "RISC-V GNU toolchain already installed, skipping..."
fi

export PATH=$PATH:$BASE_DIR/toolchains/gcc-riscv/bin

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

# building spike (risc-v isa simulator)
if [ ! -d "emulators/spike" ]; then
    echo "Cloning and building Spike RISC-V emulator..."
    git clone --revision b0d7621ff8e9520aaacd57d97d4d99a545062d14 https://github.com/riscv-software-src/riscv-isa-sim.git emulators/spike
    cd emulators/spike
    mkdir -p build
    cd build
    ../configure --prefix=$BASE_DIR/emulators/spike/install
    jobs=$( (nproc || sysctl -n hw.ncpu || echo 2) 2>/dev/null)
    make -j${jobs}
    make install
    cd $BASE_DIR
else
    echo "Spike emulator already exists, skipping build..."
fi

export PATH=$PATH:$BASE_DIR/emulators/spike/install/bin

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
if [ ! -d "plugins/spike" ] || [ ! -d "plugins/sail_cSim" ]; then
    echo "Setting up RISCOF framework with plugins..."
    
    # Setup plugins directory
    mkdir -p plugins
    
    # Initialize plugins
    riscof setup --dutname=spike
    
    # Move plugins to the correct location if they're not there already
    if [ -d "spike" ] && [ ! -d "plugins/spike" ]; then
        mv spike plugins/
    fi
    
    if [ -d "sail_cSim" ] && [ ! -d "plugins/sail_cSim" ]; then
        mv sail_cSim plugins/
    fi
    
    # Clone arch-test repository
    riscof arch-test --clone

    # Remove PMP section from spike_isa.yaml using Python's yq module
    echo "Modifying YAML file to remove PMP section..."
    python3 -m yq 'del(.hart0.PMP)' -y -i plugins/spike/spike_isa.yaml
else
    echo "RISCOF framework already set up, skipping..."
fi

# Update config.ini with correct paths using our Python script
echo "Updating config.ini with correct paths..."
python3 update_config.py

# Make run.sh executable
chmod +x run.sh

echo "Setup completed. Use './run.sh' to test the Spike simulator against the Sail reference model."
echo "Note: YOU MUST UPDATE THE SIGNATURE GRANULARITY TO 4; SEE THE README."