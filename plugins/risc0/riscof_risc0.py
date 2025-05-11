import os
import re
import shutil
import subprocess
import shlex
import logging
import random
import string
from string import Template
import sys

import riscof.utils as utils
import riscof.constants as constants
from riscof.pluginTemplate import pluginTemplate

logger = logging.getLogger()

class risc0(pluginTemplate):
    __model__ = "risc0"

    # Version of the risc0 model
    __version__ = "0.1.0"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        config = kwargs.get('config')

        # If the config node for this DUT is missing or empty. Raise an error.
        if config is None:
            print("Please enter input file paths in configuration.")
            raise SystemExit(1)

        # Path to the r0vm executable
        self.dut_exe = os.path.join(config['PATH'] if 'PATH' in config else "./emulators/risc0/target/debug", "r0vm")

        # Number of parallel jobs that can be spawned off by RISCOF
        self.num_jobs = str(config['jobs'] if 'jobs' in config else 1)

        # Path to the directory where this python file is located
        self.pluginpath = os.path.abspath(config['pluginpath'])

        # Collect the paths to the riscv-config based ISA and platform yaml files
        self.isa_spec = os.path.abspath(config['ispec'])
        self.platform_spec = os.path.abspath(config['pspec'])

        # Whether to run tests on the target
        if 'target_run' in config and config['target_run'] == '0':
            self.target_run = False
        else:
            self.target_run = True

    def initialise(self, suite, work_dir, archtest_env):
       # Capture the working directory
       self.work_dir = work_dir

       # Capture the architectural test-suite directory
       self.suite_dir = suite

       # Compiler command
       self.compile_cmd = 'riscv{1}-unknown-elf-gcc -march={0} \
         -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -g\
         -T '+self.pluginpath+'/env/link.ld\
         -I '+self.pluginpath+'/env/\
         -I ' + archtest_env + ' {2} -o {3} {4}'

    def build(self, isa_yaml, platform_yaml):
      # Load the ISA yaml as a dictionary
      ispec = utils.load_yaml(isa_yaml)['hart0']

      # Capture the XLEN value
      self.xlen = ('64' if 64 in ispec['supported_xlen'] else '32')

      # Build the ISA string for r0vm
      self.isa = 'rv' + self.xlen
      if "I" in ispec["ISA"]:
          self.isa += 'i'
      if "M" in ispec["ISA"]:
          self.isa += 'm'

      # Set the ABI
      self.compile_cmd = self.compile_cmd + ' -mabi=' + ('lp64 ' if 64 in ispec['supported_xlen'] else 'ilp32 ')

    def runTests(self, testList):
      # Delete Makefile if it already exists
      if os.path.exists(self.work_dir + "/Makefile." + self.name[:-1]):
            os.remove(self.work_dir + "/Makefile." + self.name[:-1])
      
      # Create an instance of the makeUtil class
      make = utils.makeUtil(makefilePath=os.path.join(self.work_dir, "Makefile." + self.name[:-1]))

      # Set the make command
      make.makeCommand = 'make -k -j' + self.num_jobs

      # Iterate over each test in the testList
      for testname in testList:
          # Get test details
          testentry = testList[testname]
          test = testentry['test_path']
          test_dir = testentry['work_dir']
          elf = os.path.join(test_dir, 'my.elf')
          
          # Set up the signature file path
          sig_file = os.path.join(test_dir, self.name[:-1] + ".signature")

          # Set up compile macros
          compile_macros = ' -D' + " -D".join(testentry['macros'])

          # Build the compile command
          cmd = self.compile_cmd.format(testentry['isa'].lower(), self.xlen, test, elf, compile_macros)

          # Set up the simulation command for r0vm
          if self.target_run:
            # Update to use the correct r0vm command line arguments
            simcmd = f"{self.dut_exe} --elf {elf} --output-file {sig_file}"
          else:
            simcmd = 'echo "NO RUN"'

          # Create the execution command
          execute = '@cd {0}; {1}; {2};'.format(testentry['work_dir'], cmd, simcmd)

          # Add a target to the makefile
          make.add_target(execute)

      # Execute all the make targets
      make.execute_all(self.work_dir)

      # If target runs are not required, exit
      if not self.target_run:
          raise SystemExit(0) 