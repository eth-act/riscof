#!/bin/bash

cd riscof_work/rv32i_m/M/src/
for foo in $(ls)
 do diff $foo/dut/DUT-risc0.signature $foo/ref/Reference-sail_c_simulator.signature
done

cd ../../I/src
for foo in $(ls)
 do diff $foo/dut/DUT-risc0.signature $foo/ref/Reference-sail_c_simulator.signature
done
