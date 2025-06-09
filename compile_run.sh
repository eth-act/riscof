rustup default succinct
BASE=$PWD
PATH=$PATH:$BASE/toolchains/risc0-riscv32im/bin/
mkdir -p logs

riscv32-unknown-elf-gcc \
  -march=rv32i \
  -static \
  -mcmodel=medany \
  -fvisibility=hidden \
  -nostdlib \
  -nostartfiles \
  -g \
  -T plugins/sp1/env/link.ld \
  -I plugins/sp1/env/ \
  -I riscv-arch-test/riscv-test-suite/env \
  riscv-arch-test/riscv-test-suite/rv32i_m/I/src/add-01.S \
  -o my.elf \
  -DTEST_CASE_1=True \
  -DXLEN=32 \
  -mabi=ilp32

riscv32-unknown-elf-readelf -S  my.elf > $BASE/logs/my.elf.read
riscv32-unknown-elf-objdump -D \
                            -j .text.init \
                            -j .tohost \
                            -j .data \
                            -j .riscv.attributes \
                            my.elf > $BASE/logs/my.elf.dump
mv my.elf $BASE/emulators/sp1
cd $BASE/emulators/sp1

cargo build -p sp1-perf --bin sp1-perf
cargo build -p sp1-perf --bin sp1-perf-executor

# Create empty stdin for SP1 (arch tests don't need input)
python3 -c "
import struct
# Create minimal serialized SP1Stdin: empty buffer array + ptr=0 + empty proofs
# This is a simplified bincode serialization of SP1Stdin::new()
data = struct.pack('<Q', 0) + struct.pack('<Q', 0) + struct.pack('<Q', 0)  # empty vecs and ptr=0
open('empty_stdin.bin', 'wb').write(data)
"

# ./target/debug/sp1-perf-executor --program my.elf --stdin empty_stdin.bin --executor-mode trace --signatures my.signatures
./target/debug/sp1-perf --program my.elf --stdin empty_stdin.bin --mode cpu --signatures my.signatures

# # Unified approach: ZK proof generation WITH signature collection
# echo "=== Running SP1 prover with signature collection ==="
# ELF_PATH=$(realpath my.elf)
# STDIN_PATH=$(realpath empty_stdin.bin)

# ./target/debug/sp1-perf --program "$ELF_PATH" --stdin "$STDIN_PATH" --mode cpu --signatures my.signatures && {
#     echo "✓ SP1 proof generation completed successfully!"
#     echo "✓ Signatures collected during proving process"
# } || {
#     echo "SP1 proving failed, falling back to execution-only signature collection..."
#     # Fallback: use sp1-perf-executor for signature collection if proof generation fails
#     ./target/debug/sp1-perf-executor --program my.elf --stdin empty_stdin.bin --executor-mode simple --signatures my.signatures && {
#         echo "✓ Signatures collected via executor fallback"
#     } || {
#         echo "✗ Both proving and signature collection failed"
#     }
# }

# echo "=== Summary ==="
# if [ -f "my.signatures" ]; then
#     echo "✓ Signatures saved to: my.signatures"
#     echo "✓ ZK proof generation attempted with signature collection"
# else
#     echo "✗ No signatures file generated"
# fi

# # Clean up
# # rm -f create_stdin.rs create_stdin empty_stdin.bin


 