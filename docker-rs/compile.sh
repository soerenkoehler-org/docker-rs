#!/bin/bash

source ./init.sh

cargo build --release ${OPTIONS_COMPILE[@]}

pushd target

for SRC in $(find . -mindepth 2 -type d -path "*/release"); do
    ARCH=$(basename $(dirname $SRC))
    DST="/app/target/$ARCH"
    printf "%s => %s\n" $SRC $DST
    mkdir -p "$DST"
    cp -R "$SRC" "$DST"
    chmod -R 777 "$DST"
done

popd
