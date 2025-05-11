#!/usr/bin/env python3
import configparser
import os
import sys

base_dir = os.getcwd()

config = configparser.ConfigParser()

# Read existing config and update paths
config.read('config.ini')

# RISCOF section
if 'RISCOF' not in config:
    config['RISCOF'] = {}
config['RISCOF']['ReferencePlugin'] = 'sail_cSim'
config['RISCOF']['ReferencePluginPath'] = f'{base_dir}/plugins/sail_cSim'
config['RISCOF']['DUTPlugin'] = 'risc0'  # Changed to use risc0 as the DUT
config['RISCOF']['DUTPluginPath'] = f'{base_dir}/plugins/risc0'  # Updated path

# spike section (keep as reference)
if 'spike' not in config:
    config['spike'] = {}
config['spike']['path'] = f'{base_dir}/emulators/spike/install/bin'
config['spike']['pluginpath'] = f'{base_dir}/plugins/spike'
config['spike']['ispec'] = f'{base_dir}/plugins/spike/spike_isa.yaml'
config['spike']['pspec'] = f'{base_dir}/plugins/spike/spike_platform.yaml'

# sail_cSim section
if 'sail_cSim' not in config:
    config['sail_cSim'] = {}
config['sail_cSim']['pluginpath'] = f'{base_dir}/plugins/sail_cSim'
config['sail_cSim']['path'] = f'{base_dir}/emulators/sail-riscv/build/c_emulator'

# risc0 section
if 'risc0' not in config:
    config['risc0'] = {}
config['risc0']['path'] = f'{base_dir}/emulators/risc0/target/debug'
config['risc0']['pluginpath'] = f'{base_dir}/plugins/risc0'
config['risc0']['ispec'] = f'{base_dir}/plugins/risc0/risc0_isa.yaml'
config['risc0']['pspec'] = f'{base_dir}/plugins/risc0/risc0_platform.yaml'
config['risc0']['jobs'] = '4'

# Write the updated config
with open('config.ini', 'w') as configfile:
    config.write(configfile)

print("Updated config.ini with correct paths and added risc0 plugin configuration.") 