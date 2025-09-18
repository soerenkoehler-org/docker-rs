#!/bin/bash

SCRIPTNAME=$(readlink -f $0)

FILE_GENERATE_TESTDATA=./generate-testdata.sh
FILE_OPTIONS=./docker-rs-options.sh

# clean working area
rm -rf /app/work/*

pushd /app/work

# copy source project
find /app/input -mindepth 1 -maxdepth 1 \
    -not -name ".git*" \
    -not -name "coverage" \
    -not -name "generated" \
    -not -name "target" \
| xargs -I {SRC} cp -rv {SRC} .

# load custom options
#
# OPTIONS_COMPILE=... for compiler
#
if [[ -e $FILE_OPTIONS ]]; then
    source $FILE_OPTIONS
fi
