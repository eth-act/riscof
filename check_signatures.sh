#!/bin/bash

cd riscof_work/riscv-arch-test/riscv-test-suite/rv32i_m/src/
for foo in $(ls) ; do diff $foo/dut/DUT-risc0.signature $foo/ref/Reference-sail_c_simulator.signature; done./che