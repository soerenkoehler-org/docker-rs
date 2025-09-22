#!/bin/bash

# generate the testcases

main() {
    create testcase_1
    create testcase_2
}

# define your testcases

testcase_1() {
    create_file file1.txt 2kiB
}

testcase_2() {
    create_file file1.txt 32kiB
}

# helper function for creating folders and data

create() {
    # for test named $1:
    # - create a test folder named $1
    # - execute the function named $1
    # - changes back to working dir
    create_dir generated/$1/data
    $1
    popd
}

create_dir() {
    # creates a folder and changes into it
    mkdir -p $1
    pushd $1
}

create_file() {
    # create a file $1 with $2 bytes of random data
    # count is bytes(!) because of iflag
    dd if=/dev/urandom of=$1 bs=1MiB count=$2 iflag=count_bytes status=none
}

# entry point

if [[ ! -e Cargo.toml ]]; then
    printf "not in project root\n"
    exit -1
fi

chmod -Rf 744 generated
rm -rf generated/*

main "$@"
