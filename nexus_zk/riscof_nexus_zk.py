import os
import re
import shutil
import subprocess
import shlex
import logging
import random
import string
from string import Template

import riscof.utils as utils
from riscof.pluginTemplate import pluginTemplate
import riscof.constants as constants
from riscv_isac.isac import isac

logger = logging.getLogger()


class nexus_zk(pluginTemplate):
    __model__ = "nexus_zkvm"
    __version__ = "0.1.0"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        config = kwargs.get('config')

        # If the config node for this DUT is missing or empty. Raise an error. At minimum we need
        # the paths to the ispec and pspec files
        if config is None:
            print("Please enter input file paths in configuration.")
            raise SystemExit(1)

        # In case of an RTL based DUT, this would be point to the final binary executable of your
        # test-bench produced by a simulator (like verilator, vcs, incisive, etc). In case of an iss or
        # emulator, this variable could point to where the iss binary is located. If 'PATH variable
        # is missing in the config.ini we can hardcode the alternate here.
        self.dut_exe = os.path.join(
            config['PATH'] if 'PATH' in config else "", "nexus")

        # Number of parallel jobs that can be spawned off by RISCOF
        # for various actions performed in later functions, specifically to run the tests in
        # parallel on the DUT executable. Can also be used in the build function if required.
        self.num_jobs = str(config['jobs'] if 'jobs' in config else 1)

        # Path to the directory where this python file is located. Collect it from the config.ini
        self.pluginpath = os.path.abspath(config['pluginpath'])

        # Collect the paths to the  riscv-config absed ISA and platform yaml files. One can choose
        # to hardcode these here itself instead of picking it from the config.ini file.
        self.isa_spec = os.path.abspath(config['ispec'])
        self.platform_spec = os.path.abspath(config['pspec'])

        self.make = config['make'] if 'make' in config else 'make'
        logger.debug(
            "Nexus zkVM plugin initialized using the following configuration.")
        for entry in config:
            logger.debug(entry+' : '+config[entry])

    def initialise(self, suite, work_dir, archtest_env):

        # capture the working directory. Any artifacts that the DUT creates should be placed in this
        # directory. Other artifacts from the framework and the Reference plugin will also be placed
        # here itself.
        self.work_dir = work_dir

        # capture the architectural test-suite directory.
        self.suite = suite

        self.objdump_cmd = 'riscv{1}-unknown-elf-objdump -D {0} > {2};'
        
        self.compile_cmd = 'riscv{1}-unknown-elf-gcc -march={0} \
         -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -g\
         -T '+self.pluginpath+'/env/link.ld\
         -I '+self.pluginpath+'/env/\
         -I ' + archtest_env

    def build(self, isa_yaml, platform_yaml):
        ispec = utils.load_yaml(isa_yaml)['hart0']
        self.xlen = ('64' if 64 in ispec['supported_xlen'] else '32')
        self.isa_yaml_path = isa_yaml
        self.isa = 'rv' + self.xlen
        self.compile_cmd = self.compile_cmd+' -mabi=' + \
            ('lp64 ' if 64 in ispec['supported_xlen'] else 'ilp32 ')
        if "I" in ispec["ISA"]:
            self.isa += 'i'
        if "M" in ispec["ISA"]:
            self.isa += 'm'
        if "C" in ispec["ISA"]:
            self.isa += 'c'
        if "F" in ispec["ISA"]:
            self.isa += 'f'
        if "D" in ispec["ISA"]:
            self.isa += 'd'
        objdump = "riscv{0}-unknown-elf-objdump".format(self.xlen)
        if shutil.which(objdump) is None:
            logger.error(
                objdump+": executable not found. Please check environment setup.")
            raise SystemExit(1)
        compiler = "riscv{0}-unknown-elf-gcc".format(self.xlen)
        if shutil.which(compiler) is None:
            logger.error(
                compiler+": executable not found. Please check environment setup.")
            raise SystemExit(1)
        if shutil.which(self.dut_exe) is None:
            logger.error(
                self.dut_exe + ": executable not found. Please check environment setup.")
            raise SystemExit(1)
        if shutil.which(self.make) is None:
            logger.error(
                self.make+": executable not found. Please check environment setup.")
            raise SystemExit(1)

    def runTests(self, testList, cgf_file=None, header_file=None):
        if os.path.exists(self.work_dir + "/Makefile." + self.name[:-1]):
            os.remove(self.work_dir + "/Makefile." + self.name[:-1])
        make = utils.makeUtil(makefilePath=os.path.join(
            self.work_dir, "Makefile." + self.name[:-1]))
        make.makeCommand = self.make + ' -j' + self.num_jobs
        for file in testList:
            testentry = testList[file]
            test = testentry['test_path']
            test_dir = testentry['work_dir']
            test_name = test.rsplit('/', 1)[1][:-2]

            elf = 'ref.elf'

            execute = "@cd "+testentry['work_dir']+";"
            cmd = self.compile_cmd.format(
                testentry['isa'].lower(), self.xlen) + ' ' + test + ' -o ' + elf
            compile_cmd = cmd + ' -D' + " -D".join(testentry['macros'])
            execute += compile_cmd+";"
            execute += self.objdump_cmd.format(elf, self.xlen, 'ref.disass')

            sig_file = os.path.join(test_dir, self.name[:-1] + ".signature")

            # Run the Nexus zkVM emulator
            # Using the execute command from the CLI
            execute += f"{self.dut_exe} execute {elf} --signature={sig_file} --signature-granularity=4 > {test_name}.log 2>&1;"

            cov_str = ' '
            for label in testentry['coverage_labels']:
                cov_str += ' -l '+label

            cgf_mac = ' '
            header_file_flag = ' '
            if header_file is not None:
                header_file_flag = f' -h {header_file} '
                cgf_mac += ' -cm common '
                for macro in testentry['mac']:
                    cgf_mac += ' -cm '+macro

            if cgf_file is not None:
                coverage_cmd = 'riscv_isac --verbose info coverage -d \
                        -t {0}.log --parser-name c_sail -o coverage.rpt  \
                        --sig-label begin_signature  end_signature \
                        --test-label rvtest_code_begin rvtest_code_end \
                        -e ref.elf -c {1} -x{2} {3} {4} {5};'.format(
                    test_name, ' -c '.join(cgf_file), self.xlen, cov_str, header_file_flag, cgf_mac)
            else:
                coverage_cmd = ''

            print(f"execute command: {execute}")
            execute += coverage_cmd

            make.add_target(execute)
        make.execute_all(self.work_dir)
