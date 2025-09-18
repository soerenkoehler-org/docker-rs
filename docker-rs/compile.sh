#!/bin/bash

source ./init.sh

cargo build \
    --release \
    "$OPTIONS_COMPILE"

pushd target

for SRC in $(find . -type d -path "*/release"); do
    DST="/app/target/$SRC"
    mkdir -p "$DST"
    cp -R "$SRC" "$DST"
    chmod -R 777 "$DST"
done

popd
