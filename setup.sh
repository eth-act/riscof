sudo apt install build-essential libgmp-dev z3 pkg-config zlib1g-dev cmake curl texinfo

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