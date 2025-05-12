Following https://riscof.readthedocs.io/en/stable/installation.html 
I hit an error `ImportError: cannot import name 'preprocessing' from 'riscv_isac.isac'`. This is discussed in https://github.com/riscv-software-src/riscof/issues/128 where the workaround is to manually install a newer version of riscv-isac (Instruction Set Architecture Coverage; measures how many features are covered). Command: pip install git+https://github.com/riscv-non-isa/riscv-arch-test/#subdirectory=riscv-isac.

Many issues... made setup.sh along the way...

Hit
```
(.venv) ubuntu@ip-172-31-19-46:~/riscof$ riscof validateyaml --config=config.ini
    INFO | ****** RISCOF: RISC-V Architectural Test Framework 1.25.3 *******
    INFO | using riscv_isac version : 0.18.0
    INFO | using riscv_config version : 3.18.3
    INFO | Reading configuration from: /home/ubuntu/riscof/config.ini
    INFO | Preparing Models
    INFO | Input-ISA file
    INFO | ISACheck: Loading input file: /home/ubuntu/riscof/spike/spike_isa.yaml
    INFO | ISACheck: Load Schema /home/ubuntu/riscof/.venv/lib/python3.12/site-packages/riscv_config/schemas/schema_isa.yaml
    INFO | ISACheck: Processing Hart:0
    INFO | ISACheck: Initiating Validation for Hart:0
   ERROR | ISACheck: Error in /home/ubuntu/riscof/spike/spike_isa.yaml.
   ERROR |  PMP:
   ERROR |   - unknown field
```

LLM:
```
To summarize what we did to solve your issue:
We removed the PMP block from your spike_isa.yaml file because it was using an incorrect format that was not recognized by the current version of RISCV_Config (3.18.3).
The YAML validator automatically added the required pmp_granularity field with the default value of 0.
The error was caused by the format of the PMP configuration in the YAML file. It appears that either:
The format in the template file you were using was outdated, or
The RISCV_Config schema has changed between versions.
Now your validation is working correctly, and you can proceed with using RISCOF for your RISC-V testing.
```

Python error on missing signature file resolved by resetting to a commit prior to 17cfdec13b99e61da9fdf8c32d21b33e008bd82d (prior commit is 03ceb5ba24e88c82a0bbe0c776afb8702057e81a) which changed some CLI flags.




Accidentally created 500GB of logs. Needed to update a line in `sail_cSim/riscof_sail_cSim.py` to 
```
execute += self.sail_exe[self.xlen] + '  -i -v {0} --signature-granularity=4 --test-signature={1} {2} > {3}.log 2>&1;'.format(pmp_flags, sig_file, elf,test_name)
```
(remove ram field to match `riscof/spike/riscof_spike.py`ure)

and also add lines in the `config.ini`
```
ispec=/home/cody/share/work/zkVMs/riscof/spike/spike_isa.yaml
pspec=/home/cody/share/work/zkVMs/riscof/spike/spike_platform.yaml
```

# riscv-tests

After struggling to repro the tests in `risc0/risc0/circuit/rv32im/src/prove`. Seem to have things working. Setup:

```
git clone git@github.com:riscv-software-src/riscv-tests.git && cd riscv-tests && git submodule update --init --recursive && autoconf
```
then configure with 
```
./configure CC=riscv32-unknown-elf-gcc --with-xlen=32 CFLAGS="-march=rv32im -nostdlib -mabi=ilp32"
```
where 
```
% riscv32-unknown-elf-gcc --version
riscv32-unknown-elf-gcc (gc891d8dc23e) 13.2.0
```
and this is the toolchain release https://github.com/risc0/toolchain/ (most recent, I think). I was hitting unimplemented CSR instructions (cf https://github.com/riscv-software-src/riscv-tests/issues/368). This comes from some testing macro, so I searched for this in RISC0 repo and found https://github.com/risc0/zirgen/blob/eb1785e79add49f59f3ac17d4364f26811cdaa41/zirgen/circuit/rv32im/v1/test/riscv_test.h. This didn't work because of the use of global pointer, but

```
// Copyright 2024 RISC Zero, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#define __riscv_xlen 32
#define TESTNUM x31

#define RVTEST_RV32U                                                                               \
  .macro init;                                                                                     \
  .endm

#define RVTEST_FAIL                                                                                \
  fence;                                                                                           \
  unimp

#define RVTEST_PASS                                                                                \
  li t0, 0;                                                                                        \
  li a0, 0;                                                                                        \
  li a1, 0x400;                                                                                    \
  ecall

#define RVTEST_CODE_BEGIN                                                                          \
  .text;                                                                                           \
  .globl _start;                                                                                   \
  _start:                                                                                          \
  /* Initialize registers */                                                                       \
  li x1, 0;                                                                                        \
  li x2, 0;                                                                                        \
  li x3, 0;                                                                                        \
  li x4, 0;                                                                                        \
  li x5, 0;                                                                                        \
  li x6, 0;                                                                                        \
  li x7, 0;                                                                                        \
  li x8, 0;                                                                                        \
  li x9, 0;                                                                                        \
  li x10, 0;                                                                                       \
  li x11, 0;                                                                                       \
  li x12, 0;                                                                                       \
  li x13, 0;                                                                                       \
  li x14, 0;                                                                                       \
  li x15, 0;                                                                                       \
  li x16, 0;                                                                                       \
  li x17, 0;                                                                                       \
  li x18, 0;                                                                                       \
  li x19, 0;                                                                                       \
  li x20, 0;                                                                                       \
  li x21, 0;                                                                                       \
  li x22, 0;                                                                                       \
  li x23, 0;                                                                                       \
  li x24, 0;                                                                                       \
  li x25, 0;                                                                                       \
  li x26, 0;                                                                                       \
  li x27, 0;                                                                                       \
  li x28, 0;                                                                                       \
  li x29, 0;                                                                                       \
  li x30, 0;                                                                                       \
  li x31, 0;

#define RVTEST_CODE_END

#define RVTEST_DATA_BEGIN .data
#define RVTEST_DATA_END
```
seems to get the job done (need to validate, this is AI generated... but at least it executes, proves and verifies). Note that only some of the test artifacts build but at least the basic addition test does. 

Testing command: from riscof/emulators/risc0/risc0/circuit/rv32im/src/prove/testdata run
```
rm -rf riscv-tests && mkdir riscv-tests && cp $BASE/riscv-tests/isa/rv32ui-p-add riscv-tests/add && tar czvf riscv-tests.tgz riscv-tests/ && cargo test -p risc0-circuit-rv32im prove::tests::riscv::add -- --nocapture --exact
```

AH but actually you can just add the global poitner address ot the linker env/p/link.ld data section as in 
```
  .data : { 
    __global_pointer$ = . + 0x800;
    *(.data) 
  }
```
and things are still good.

TODO: record revisions.