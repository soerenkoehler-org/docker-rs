#!/bin/bash

if [[ ! -e Cargo.toml ]]; then
    printf "not in project root\n"
    exit -1
fi

./build/test.sh

nginx -c $(readlink -e ./build/nginx.conf) -p $(pwd)/coverage
