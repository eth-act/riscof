#!/bin/bash
set -eu

mkdir -p toolchains emulators

# Install RISC0-published rv32im toolchain if not already installed
if [ ! -d "toolchains/risc0-riscv32im" ]; then
  echo "Downloading and installing RISC0 toolchain..."
  curl -L https://github.com/risc0/toolchain/releases/download/2024.01.05/riscv32im-linux-x86_64.tar.xz | tar -xJ -C toolchains/
  mv toolchains/riscv32im-linux-x86_64 toolchains/risc0-riscv32im
else
  echo "RISC0 toolchain already installed, skipping..."
fi

# Install "golden model" Sail RISC-V simulator if not already installed (the reference)
if [ ! -d "emulators/sail-riscv" ]; then
  echo "Downloading and installing Sail model..."
  curl -L https://github.com/riscv/sail-riscv/releases/download/0.7/sail_riscv-Linux-x86_64.tar.gz | tar -xz -C emulators/
  mv emulators/sail_riscv-Linux-x86_64 emulators/sail-riscv
else
  echo "Sail model already exists, skipping..."
fi

# Building r0vm, RISC0 emulator (the DUT)
if [ ! -d "emulators/risc0" ]; then
  git clone -b cg/riscof https://github.com/codygunton/risc0.git emulators/risc0
fi

# debug build by default
echo "Building RISC0 emulator; this may take several minutes..."
cargo build -p risc0-r0vm --manifest-path emulators/risc0/Cargo.toml --quiet

# Set up python environment for RISCOF testing framework
if [ ! -d ".venv" ]; then
  echo "Setting up Python virtual environment..."
  python3 -m venv .venv
  source .venv/bin/activate
  python3 -m pip install -r requirements.txt
else
  echo "Python virtual environment already exists, activating..."
  source .venv/bin/activate
fi

# Get architectural tests if not already cloned
if [ ! -d "riscv-arch-test" ]; then
  # Clone arch-test repository; pinning a version, but others may work too
  riscof arch-test --clone --get-version 3.9.1
else
  echo "RISCOF framework already set up, skipping..."
fi

echo "Setup completed. Use './run.sh' to test the Spike simulator against the Sail reference model."
