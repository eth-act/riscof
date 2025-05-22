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
  -T plugins/risc0/env/link.ld \
  -I plugins/risc0/env/ \
  -I riscv-arch-test/riscv-test-suite/env \
  riscv-arch-test/riscv-test-suite/rv32i_m/I/src/add-01.S \
  -o my.elf \
  -DTEST_CASE_1=True \
  -DXLEN=32 \
  -mabi=ilp32

riscv32-unknown-elf-readelf -S  my.elf > $BASE/logs/my.elf.read
riscv32-unknown-elf-objdump -d my.elf > $BASE/logs/my.elf.dump
mv my.elf $BASE/emulators/risc0
cd $BASE/emulators/risc0

cargo build -p risc0-r0vm 

# # riscof test we just compiled for dut
# timeout --signal=SIGTERM --kill-after=1s 1s env RUST_LOG=trace ./target/debug/r0vm --test-elf my.elf --receipt my.receipt | $BASE/strip_ansi.sh > ${BASE}/logs/bad_trace.log

# riscof test compiled for ref
timeout --signal=SIGTERM --kill-after=1s 1s env RUST_LOG=trace ./target/debug/r0vm --test-elf $BASE/riscof_work/rv32i_m/I/src/add-01.S/ref/ref.elf --receipt my.receipt | $BASE/strip_ansi.sh > $BASE/logs/bad_trace.log

# # riscv-test
# timeout --signal=SIGTERM --kill-after=1s 5s env RUST_LOG=trace ./target/debug/r0vm --test-elf $BASE/riscv-tests/isa/build/add | $BASE/strip_ansi.sh > $BASE/logs/good_trace.log


