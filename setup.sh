#!/bin/bash
set -e  # Exit on error

# Install dependencies
sudo apt-get update
sudo apt-get install -y opam build-essential libgmp-dev z3 pkg-config zlib1g-dev cmake curl

# Initialize opam
opam init -y --disable-sandboxing
eval $(opam env)

# Create ocaml switch and install dependencies
opam switch create ocaml-base-compiler.4.06.1
eval $(opam env)
opam install -y sail

# Clone and build sail-riscv
git clone https://github.com/riscv/sail-riscv.git
cd sail-riscv

# Build the C emulator
./build_c_emulator.sh

# Make symbolic links
cd ..
sudo ln -sf $(pwd)/sail-riscv/c_emulator/riscv_sim_RV64 /usr/bin/riscv_sim_RV64
sudo ln -sf $(pwd)/sail-riscv/c_emulator/riscv_sim_RV32 /usr/bin/riscv_sim_RV32

echo "Setup complete! The sail-riscv emulator should now be installed."