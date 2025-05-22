#!/bin/bash

# Strip ANSI escape sequences from stdin
sed 's/\x1b\[[0-9;]*[mGKH]//g'