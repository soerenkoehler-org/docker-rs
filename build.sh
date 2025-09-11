#!/bin/bash

# TODO create one single top level script
# TODO use some config in working dir
# TODO use script dir for nginx-config

SCRIPT=$(readlink -e "$0")
SCRIPTDIR=$(dirname "$SCRIPT")

IMG_REMOTE=ghcr.io/soerenkoehler-org/docker-rs-cmish:dev
IMG=docker-rs:latest

# check working dir
if [[ ! -e Cargo.toml ]]; then
    printf "not in project root\n"
    exit -1
fi

# prepare output directories


# handle input

case $1 in

update)
    docker pull $IMG_REMOTE
    docker tag $IMG_REMOTE $IMG
;;

shell)
printf "not implemented\n"
;;

compile)
printf "not implemented\n"
;;

test)
printf "not implemented\n"
;;

coverage)
printf "not implemented\n"
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