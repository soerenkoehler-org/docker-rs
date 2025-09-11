#!/bin/bash

create() {
    create_dir generated/$1/data
    $1
    popd
}

create_dir() {
    mkdir -p $1
    pushd $1
}

create_file() {
    dd if=/dev/urandom of=$1 bs=1MiB count=$2 iflag=count_bytes status=none
}

filelist_test() {
    for N in {0..15}; do
        mkdir -p dir$(($N/8%2))/dir$(($N/4%2))/dir$(($N/2%2))/dir$(($N%2))
    done

    for DIR in $(find . -type d); do
        for N in {1..5}; do
            create_file $DIR/file$N.dat 0
        done
    done

    find . -type f \
    | sed 's/^\.\///' \
    | sort >../all_files.txt

    find . -type f \
    -not -path "./file3.dat" \
    | sed 's/^\.\///' \
    | sort >../specific_one_pattern.txt

    find . -type f \
    -not -path "./dir0/file2.dat" \
    -not -path "./dir1/file4.dat" \
    | sed 's/^\.\///' \
    | sort >../specific_two_patterns.txt

    find . -type f \
    -not -path "**/file3.dat" \
    | sed 's/^\.\///' \
    | sort >../wildcard_one_pattern.txt

    find . -type f \
    -not -path "**/dir0/file2.dat" \
    -not -path "**/dir1/file4.dat" \
    | sed 's/^\.\///' \
    | sort >../wildcard_two_patterns.txt
}

filelist_test_baddir() {
    mkdir -p dir-unreachable
    chmod 000 dir-unreachable
}

filelist_test_badsymlink() {
    ln -s file1 symlink-to-file1
}

config_test_unreadable_file() {
    touch unreadable.json
    chmod 000 unreadable.json
}

config_test_unwritable_file() {
    chmod 555 .
}

digest_test() {
    # create_file empty.dat 0
    # printf "content of first file" >file1.dat
    # printf "content of second file" >file2.dat

    cd ..
    # truncate -s 0 sha256.txt
    # truncate -s 0 sha512.txt
    # for FILE in $(find data -type f); do
    #     sha256sum $FILE >>sha256.txt
    #     sha512sum $FILE >>sha512.txt
    # done

    truncate -s 0 unreadable.txt
    chmod 000 unreadable.txt
}

if [[ ! -e Cargo.toml ]]; then
    printf "not in project root\n"
    exit -1
fi

chmod -Rf 744 generated
rm -rf generated/*

create filelist_test
create filelist_test_baddir
create filelist_test_badsymlink
create config_test_unreadable_file
create config_test_unwritable_file
create digest_test
