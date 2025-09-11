#!/bin/bash

DISTDIR=$(readlink -f ./dist)
NAME_REPLACEMENT='s/rs-chdiff/chdiff/'

BINARIES=$(find ./target \
    -type f \
    -path "*/release/*" \
    \( -name "rs-chdiff" -or -name "rs-chdiff.exe" \) )

mkdir -p $DISTDIR

for BIN in $BINARIES; do
    ARTIFACT=$(dirname $BIN)/$(sed $NAME_REPLACEMENT <<< $(basename $BIN))

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

    DISTNAME="$DISTDIR/chdiff-$(date -I)-$ARCH"

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

pushd ./coverage/html
zip -v9r "$DISTDIR/chdiff-$(date -I)-coverage.zip" \
    ./* \
    -x *.lcov \
    -x nginx*
popd
