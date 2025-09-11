#!/bin/bash

# check working dir
if [[ ! -e Cargo.toml ]]; then
    printf "not in project root\n"
    exit -1
fi

# TODO create one single top level script
# TODO use some config in working dir
# TODO use script dir for nginx-config
