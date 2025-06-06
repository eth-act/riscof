rustup default succinct
BASE=$PWD
PATH=$PATH:$BASE/toolchains/risc0-riscv32im/bin/

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

cargo build -p sp1-perf --bin sp1-perf-executor

# Create empty stdin for SP1 (arch tests don't need input)
python3 -c "
import struct
# Create minimal serialized SP1Stdin: empty buffer array + ptr=0 + empty proofs
# This is a simplified bincode serialization of SP1Stdin::new()
data = struct.pack('<Q', 0) + struct.pack('<Q', 0) + struct.pack('<Q', 0)  # empty vecs and ptr=0
open('empty_stdin.bin', 'wb').write(data)
"

./target/debug/sp1-perf-executor --program my.elf --stdin empty_stdin.bin --executor-mode simple

# echo "Running test a few times to catch intermittent failures..."
# for i in {1..10}; do
#     echo "=== Run $i ==="
#     RUST_BACKTRACE=1 ./target/debug/r0vm --test-elf my.elf --signatures my.signatures
#     # RUST_BACKTRACE=1 RAYON_NUM_THREADS=1 RUSTFLAGS="--cfg single_threaded" ./target/debug/r0vm --test-elf my.elf --signatures my.signatures
#     echo ""
# done

# # Run with Valgrind multiple times to catch intermittent double free
# echo "Running with Valgrind multiple times to catch intermittent memory corruption..."
# for i in {1..15}; do
#     echo "=== Valgrind Run $i ==="
#     # Specific flags for double-free detection and heap corruption
#     valgrind --tool=memcheck \
#              --leak-check=full \
#              --show-leak-kinds=all \
#              --track-origins=yes \
#              --freelist-vol=10000000 \
#              --freelist-big-blocks=10000000 \
#              --expensive-definedness-checks=yes \
#              --track-fds=yes \
#              --log-file=valgrind_run_${i}.log \
#              ./target/debug/r0vm --test-elf my.elf --signatures my.signatures
    
#     exit_code=$?
#     echo "Exit code: $exit_code"
    
#     # Check if we caught any errors
#     if grep -q "ERROR SUMMARY: [1-9]" valgrind_run_${i}.log; then
#         echo "Found memory errors in run $i!"
#         break
#     fi
#     echo ""
# done

# # riscof test compiled for ref
# timeout --signal=SIGTERM --kill-after=1s 1s env RUST_LOG=trace ./target/debug/r0vm --test-elf $BASE/riscof_work/rv32i_m/I/src/add-01.S/ref/ref.elf --receipt my.receipt | $BASE/strip_ansi.sh > $BASE/logs/ref_trace.log

# # riscv-test
# timeout --signal=SIGTERM --kill-after=1s 5s env RUST_LOG=trace ./target/debug/r0vm --test-elf $BASE/riscv-tests/isa/build/add | $BASE/strip_ansi.sh > $BASE/logs/rvtests_trace.log


