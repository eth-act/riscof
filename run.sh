#!/bin/bash

set -eu

# Set up paths
PATH=$PATH:$PWD/toolchains/risc0-riscv32im/bin/
PATH=$PATH:$PWD/emulators/sail-riscv/bin/
PATH=$PATH:$PWD/emulators/risc0/target/debug/

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

# Generate test list
echo "Generating test list..."
riscof testlist --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env

# Set timeout to prevent infinite loops
echo "Running RISCOF tests with timeout protection..."
timeout --foreground 30m riscof run --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env

# Check if timeout occurred
if [ $? -eq 124 ]; then
    echo "Error: Tests timed out after 30 minutes. There might be an infinite loop in the test execution."
    exit 1
else
    echo "Tests completed successfully!"
fi 