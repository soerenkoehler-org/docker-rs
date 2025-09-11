#!/bin/bash

if [[ ! -e Cargo.toml ]]; then
    printf "not in project root\n"
    exit -1
fi

mkdir -p target
chmod 777 target

docker run \
  --mount type=bind,src=.,dst=/app/input,ro \
  --mount type=bind,src=./target,dst=/app/target \
  --rm docker-rs:latest bash compile.sh
