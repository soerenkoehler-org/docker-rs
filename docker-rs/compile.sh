#!/bin/bash

SCRIPTNAME=$(readlink -f $0)

./init.sh

pushd /app/work

cargo build \
    --release \
    --target x86_64-pc-windows-gnu \
    --target x86_64-unknown-linux-gnu \
    --target armv7-unknown-linux-gnueabi \
    --target aarch64-unknown-linux-gnu

pushd target

for SRC in $(find . -type d -path "*/release"); do
    DST="/app/target/$SRC"
    mkdir -p "$DST"
    cp -R "$SRC" "$DST"
    chmod -R 777 "$DST"
done

popd
popd
