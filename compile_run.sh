# rustup default nightly
PATH=$PATH:$PWD/toolchains/risc0-riscv32im/bin/

i=0
for elf in ~/.conduit/elfs/risc0_*.elf; do
  echo "dump $i"
  riscv32-elf-readelf -S $elf >logs/read_$i
  riscv32-elf-objdump -dC \
    -j .text.init \
    $elf >logs/dump_$i
  cat logs/dump_$i | grep csr
  let i+=1
done

cp ~/.conduit/elfs/risc0_1.elf emulators/risc0/my.elf
cd emulators/risc0
CARGO_TERM_WARNINGS=false RUSTFLAGS="-Awarnings" cargo build -p risc0-r0vm
RUST_BACKTRACE=1 ./target/debug/r0vm --test-elf my.elf
