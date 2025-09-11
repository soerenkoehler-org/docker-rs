#!/bin/bash

SCRIPTNAME=$(readlink -f $0)

rm -rf /app/work/*

pushd /app/work

find /app/input -mindepth 1 -maxdepth 1 \
    -not -name ".git*" \
    -not -name "coverage" \
    -not -name "generated" \
    -not -name "target" \
| xargs -I {SRC} cp -rv {SRC} .

popd
