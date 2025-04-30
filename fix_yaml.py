#!/usr/bin/env python3

import yaml
import sys

def remove_pmp(filename):
    with open(filename, 'r') as f:
        data = yaml.safe_load(f)
    
    if 'hart0' in data and 'pmp' in data['hart0']:
        del data['hart0']['pmp']
        print(f"Removed PMP section from {filename}")
    
    with open(filename, 'w') as f:
        yaml.dump(data, f, default_flow_style=False)

def fix_platform(filename):
    with open(filename, 'r') as f:
        data = yaml.safe_load(f)
    
    # Remove the hart sections
    if 'hart_ids' in data:
        del data['hart_ids']
        print(f"Removed hart_ids from {filename}")
    
    if 'hart0' in data:
        del data['hart0']
        print(f"Removed hart0 from {filename}")
    
    with open(filename, 'w') as f:
        yaml.dump(data, f, default_flow_style=False)

if __name__ == "__main__":
    isa_files = [
        "nexus_zk/nexus_isa.yaml",
        "sail_cSim/sail_cSim_isa.yaml"
    ]
    
    platform_files = [
        "nexus_zk/nexus_platform.yaml",
        "sail_cSim/sail_cSim_platform.yaml"
    ]
    
    for file in isa_files:
        try:
            remove_pmp(file)
        except Exception as e:
            print(f"Error processing {file}: {e}")
    
    for file in platform_files:
        try:
            fix_platform(file)
        except Exception as e:
            print(f"Error processing {file}: {e}") 