#!/bin/bash

# Set up paths
PATH=$PATH:$PWD/riscv-gnu-toolchain/bin/
PATH=$PATH:$PWD/sail/bin
PATH=$PATH:$PWD/sail-riscv/build/c_emulator
PATH=$PATH:$PWD/riscv-isa-sim/build

# Set Rust logging
# Possible values: error, warn, info, debug, trace
export RUST_LOG=debug
# Set to 1 for basic backtrace, full for detailed backtrace
export RUST_BACKTRACE=1

# Activate the Python environment
if [ -d ".venv" ]; then
    source .venv/bin/activate
else
    echo "Python virtual environment not found. Please run setup.sh first."
    exit 1
fi

# Clean up previous test run data
if [ -d "riscof_work" ]; then
    echo "Cleaning up previous test run data..."
    rm -rf riscof_work
fi

# Validate YAML configuration
echo "Validating YAML configuration..."
riscof validateyaml --config=config.ini

# Define the supported test directories (only RV32I and RV32M)
SUPPORTED_DIRS="riscv-arch-test/riscv-test-suite/rv32i_m/I riscv-arch-test/riscv-test-suite/rv32i_m/M"

# Generate test list for supported extensions only
echo "Generating test list for RV32I and RV32M only..."
for dir in $SUPPORTED_DIRS; do
    echo "Adding tests from $dir"
    riscof testlist --config=config.ini --suite=$dir/src --env=riscv-arch-test/riscv-test-suite/env
done

# Set timeout to prevent infinite loops
echo "Running RISCOF tests with timeout protection..."
timeout --foreground 30m riscof run --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env

# Check if timeout occurred
if [ $? -eq 124 ]; then
    echo "Error: Tests timed out after 30 minutes. There might be an infinite loop in the test execution."
    exit 1
else
    echo "Tests completed"
fi 