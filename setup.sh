sudo apt install build-essential \
    libgmp-dev \
    z3 \
    pkg-config \
    zlib1g-dev \
    cmake \
    curl \
    texinfo \
    autoconf \
    automake \
    autotools-dev \
    python3 \
    libmpc-dev \
    libmpfr-dev \
    gawk \
    bison \
    flex \
    gperf \
    libtool \
    patchutils \
    bc \
    libexpat-dev

curl -L https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2025.01.20/riscv32-elf-ubuntu-24.04-gcc-nightly-2025.01.20-nightly.tar.xz -o riscv-gnu-toolchain.tar.xz
tar -xf riscv-gnu-toolchain.tar.xz
mv riscv riscv-gnu-toolchain
rm riscv-gnu-toolchain.tar.xz
PATH=$PATH:$PWD/riscv-gnu-toolchain/bin/

curl -L https://github.com/rems-project/sail/releases/download/0.19-linux-binary/sail.tar.gz -o sail.tar.gz
tar -xzf sail.tar.gz
rm sail.tar.gz
export PATH=$PATH:$PWD/sail/bin

git clone https://github.com/riscv/sail-riscv.git
cd sail-riscv
./build_simulators.sh

python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt

riscof setup --dutname=spike
riscof arch-test --clone
riscof validateyaml --config=config.ini
riscof testlist --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env
ln -s sail-riscv/c_emulator/riscv_sim_RV32 /usr/bin/riscv_sim_RV32