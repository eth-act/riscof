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

After struggling to repro the tests in `risc0/risc0/circuit/rv32im/src/prove`. Seem to have things working. For now the setup script the setup script `setup_riscv_tests.sh` handles everything.


I was hitting unimplemented CSR instructions (cf https://github.com/riscv-software-src/riscv-tests/issues/368). This comes from some testing macro, so I searched for this in RISC0 repo and found https://github.com/risc0/zirgen/blob/eb1785e79add49f59f3ac17d4364f26811cdaa41/zirgen/circuit/rv32im/v1/test/riscv_test.h. This didn't work because of the use of global pointer, but making changes as in  to get a new riscv_test.h and link.d for the p set of tests gets the job done.

Testing command: from riscof/emulators/risc0/risc0/circuit/rv32im/src/prove/testdata run
```
rm -rf riscv-tests && mkdir riscv-tests && cp $BASE/riscv-tests/isa/rv32ui-p-add riscv-tests/add && tar czvf riscv-tests.tgz riscv-tests/ && cargo test -p risc0-circuit-rv32im prove::tests::riscv::add -- --nocapture --exact
```
or remove the filter to run them all (takes ~1m on my home desktop).