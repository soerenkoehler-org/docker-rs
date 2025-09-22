#!/bin/bash

main() {
    dispatch_command $@
}

dispatch_command() {
    # handle input

    case $1 in

    update)
        docker_init
        docker pull $IMG_REMOTE
        docker tag $IMG_REMOTE $IMG_LOCAL
    ;;

    shell)
        initialize $0
        docker_run --user root -it
    ;;

    compile)
        initialize $0
        rm -r $DIR_TARGET/*
        docker_run -- compile.sh
    ;;

    test)
        initialize $0
        rm -r $DIR_COVERAGE/*
        docker_run -- test.sh
    ;;

    coverage)
        initialize $0
        rm -r $DIR_COVERAGE/*
        docker_run -- test.sh
        nginx -c $DIR_THIS_SCRIPT/nginx.conf -p $DIR_COVERAGE
    ;;

    package)
        # FIXME read binary name from Cargo.toml
        if [[ -z $2 || -z $3 ]]; then
            printf "%s\n" \
                "usage:" \
                "docker-rs package SOURCE_BINARY_NAME TARGET_ARTIFACT_NAME"
            exit -1
        fi
        initialize $0
        rm -r $DIR_DIST/*
        package $2 $3
    ;;

    release)
        initialize $0
        release
    ;;

    *)
        printf "missing or wrong command\n"
    ;;

    esac
}

initialize() {
    # check working dir
    if [[ ! -e Cargo.toml ]]; then
        printf "not in project root\n"
        exit -1
    fi

    DIR_THIS_SCRIPT=$(dirname $(readlink -e $1))

    # prepare output directories
    DIR_PROJECT=.
    DIR_TARGET=./target
    DIR_COVERAGE=./coverage
    DIR_DIST=./dist

    for DIR in $DIR_COVERAGE $DIR_TARGET $DIR_DIST; do
        mkdir -v -p $DIR
        chmod -v 777 $DIR
    done

    docker_init
}

docker_init() {
    local TAG=$1
    if [[ -z $TAG ]];then
        TAG=main
    fi

    IMG_REMOTE=ghcr.io/soerenkoehler-org/docker-rs:$TAG
    IMG_LOCAL=docker-rs:latest

    RUN_DOCKER_RS=""
}

docker_run() {
    local OPTIONS=(
        --mount type=bind,src=$DIR_PROJECT,dst=/app/input,ro
        --mount type=bind,src=$DIR_TARGET,dst=/app/target
        --mount type=bind,src=$DIR_COVERAGE,dst=/app/coverage
        --rm
    )
    while [[ $# > 0 ]]; do
        if [[ $1 == "--" ]]; then
            shift
            break
        else
            OPTIONS+=($1)
            shift
        fi
    done

    docker run ${OPTIONS[@]} $IMG_LOCAL $CMD bash $@
}

package() {
    local NAME_REPLACEMENT="s/$1/$2/"

    local BINARIES=$(find ./target \
        -type f \
        -path "*/release/*" \
        \( -name "$1" -or -name "$1.exe" \) )

    local ARCH
    local BIN
    for BIN in $BINARIES; do
        local ARTIFACT=$(dirname $BIN)/$(sed $NAME_REPLACEMENT <<< $(basename $BIN))

        mv -v $BIN $ARTIFACT

        case $(basename $(dirname $(dirname $BIN))) in
        armv7*)
            ARCH=armV7
            ;;
        aarch64*)
            ARCH=arm64
            ;;
        x86_64-pc-windows-gnu)
            ARCH=win64
            ;;
        x86_64-unknown-linux-gnu)
            ARCH=linux
            ;;
        esac

        local DISTNAME="$DIR_DIST/$1-$(date -I)-$ARCH"

        case $ARCH in
        *win64*)
            zip -v9jo "$DISTNAME.zip" "$ARTIFACT"
            ;;
        *)
            tar -cf "$DISTNAME.tar" \
                -C $(dirname "$ARTIFACT") \
                $(basename $ARTIFACT)
            gzip -v9f "$DISTNAME.tar"
            ;;
        esac

        printf "\n"
    done

    COVERAGE_ZIP="$(readlink -e $DIR_DIST)/$1-$(date -I)-coverage.zip"

    pushd $DIR_COVERAGE
    zip -v9r "$COVERAGE_ZIP" \
        ./* \
        -x *.lcov \
        -x nginx*
    popd
}

release() {
    printf "verify github auth status:\n%s\n\n" "$(gh auth status)"

    if [[ $GITHUB_REF_TYPE == 'tag' ]]; then
        create_release_prod
    elif [[ $GITHUB_REF_TYPE == 'branch' ]]; then
        create_release_nightly
    fi

    if [[ -e $DIR_DIST ]]; then
        upload_artifacts
    else
        printf "no artifacts to upload\n"
    fi
}

create_release_prod() {
    RELEASE=$GITHUB_REF_NAME

    local EXISTING=$(gh release list \
        --json tagName \
        --jq "[.[] | select(.tagName == \"$RELEASE\").tagName][0]")

    if [[ -z $EXISTING ]]; then
        printf "create new release '%s'\n" $RELEASE
        gh release create \
            --title $RELEASE \
            --notes "$(date +'%Y-%m-%d %H:%M:%S')" \
            --verify-tag \
            $RELEASE
    else
        printf "use existing release '%s'\n" $RELEASE
    fi
}

create_release_nightly() {
    RELEASE=nightly

    printf "create/replace release 'nightly' on branch %s\n" $GITHUB_REF_NAME

    fetch_tags

    gh release delete \
        --cleanup-tag \
        --yes \
        $RELEASE \
        2>/dev/null || true

    # Workaround for https://github.com/cli/cli/issues/8458
    printf "waiting for tag to be deleted\n"
    while fetch_tags; git tag -l | grep $RELEASE; do
        sleep 10;
        printf "still waiting...\n"
    done

    fetch_tags

    gh release create \
        --title "Nightly" \
        --notes "$(date +'%Y-%m-%d %H:%M:%S')" \
        --target $GITHUB_REF \
        --latest=false \
        $RELEASE

    fetch_tags
}

fetch_tags() {
    git fetch --all --force --tags --prune-tags --prune
}

upload_artifacts() {
    printf "uploading artifacts to '%s'\n" $RELEASE

    gh release upload --clobber $RELEASE $DIR_DIST/*
}

main "$@"
