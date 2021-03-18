#!/usr/bin/env bash

CUSTOM_COMPILE_COMMAND="./compile-requirements" pip-compile --output-file=requirements.txt setup.py "${@}"
CUSTOM_COMPILE_COMMAND="./compile-requirements" pip-compile dev-requirements.in "${@}"
