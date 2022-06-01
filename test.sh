#!/bin/bash

set -e

eval "$(conda shell.bash hook)"
source /opt/conda/etc/profile.d/conda.sh
conda activate tensorrt7

# python3.7 /test.py
