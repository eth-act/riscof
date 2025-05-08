#!/usr/bin/env python3
import configparser
import os
import sys

base_dir = os.getcwd()

config = configparser.ConfigParser()

# Read existing config and update paths
config.read('config.ini')

config['RISCOF']['ReferencePluginPath'] = f'{base_dir}/plugins/sail_cSim'
config['RISCOF']['DUTPluginPath'] = f'{base_dir}/plugins/spike'

config['spike']['path'] = f'{base_dir}/emulators/spike/install/bin'
config['spike']['pluginpath'] = f'{base_dir}/plugins/spike'
config['spike']['ispec'] = f'{base_dir}/plugins/spike/spike_isa.yaml'
config['spike']['pspec'] = f'{base_dir}/plugins/spike/spike_platform.yaml'

config['sail_cSim']['pluginpath'] = f'{base_dir}/plugins/sail_cSim'
config['sail_cSim']['path'] = f'{base_dir}/emulators/sail-riscv/build/c_emulator'

# Write the updated config
with open('config.ini', 'w') as configfile:
    config.write(configfile)

print("Updated config.ini with correct paths.") 