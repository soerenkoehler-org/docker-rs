#!/bin/bash

# TODO create one single top level script
# TODO use some config in working dir
# TODO use script dir for nginx-config

SCRIPT=$(readlink -e "$0")
SCRIPTDIR=$(dirname "$SCRIPT")

# check working dir
if [[ ! -e Cargo.toml ]]; then
    printf "not in project root\n"
    exit -1
fi

# prepare output directories

DIR_PROJECT=.
DIR_TARGET=./target
DIR_COVERAGE=./coverage

for DIR in DIR_COVERAGE DIR_TARGET; do
    mkdir -p $DIR
    chmod 777 $DIR
done

# prepare docker

IMG_REMOTE=ghcr.io/soerenkoehler-org/docker-rs-cmish:dev
IMG_LOCAL=docker-rs:latest

RUN_DOCKER_RS=docker run \
  --mount type=bind,src=$DIR_PROJECT,dst=/app/input,ro \
  --mount type=bind,src=$DIR_TARGET,dst=/app/target \
  --mount type=bind,src=$DIR_COVERAGE,dst=/app/coverage \
  --rm $IMG_LOCAL

# handle input

case $1 in

update)
    docker pull $IMG_REMOTE
    docker tag $IMG_REMOTE $IMG_LOCAL
;;

shell)
    "$RUN_DOCKER_RS" --user root -it bash
;;

compile)
    "$RUN_DOCKER_RS" compile.sh
;;

test)
    "$RUN_DOCKER_RS" test.sh
;;

coverage)
    "$RUN_DOCKER_RS" test.sh
    nginx -c $(readlink -e ./build/nginx.conf) -p $(pwd)/coverage
;;

package)
    printf "not implemented\n"
;;

release)
    printf "not implemented\n"
;;

*)
    printf "missing or wrong command\n"
;;

esac