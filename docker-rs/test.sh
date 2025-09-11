#!/bin/bash

SCRIPTNAME=$(readlink -f $0)

./init.sh

pushd /app/work

./build/generate-testdata.sh

COVERAGE_DIR=$(readlink -f "coverage")
PROFRAW_DIR="$COVERAGE_DIR/profraw"
PROFDATA_FILE="$COVERAGE_DIR/coverage.profdata"
REPORT_TEMP_FILE="$COVERAGE_DIR/coverage.lcov"
HTML_TEMP_DIR="$COVERAGE_DIR/html"

OUTPUT_DIR=/app/coverage
REPORT_FILE="$OUTPUT_DIR/coverage.lcov"

CRATE_NAME="rs-chdiff"
CRATE_NAME_FS_SAFE=$(echo "$CRATE_NAME" | tr '-' '_')

export RUSTFLAGS="-C instrument-coverage"
export LLVM_PROFILE_FILE="$PROFRAW_DIR/$CRATE_NAME-%p-%m.profraw"

cargo clean
rm -rf "$OUTPUT_DIR"/*
rm -rf "$COVERAGE_DIR"
mkdir -p "$PROFRAW_DIR"
mkdir -p "$HTML_TEMP_DIR"

# build debug binary for execution by tests
cargo b
# run tests
TEST_OUTPUT=$(cargo t --jobs 1 --message-format=json)

if [[ $? != 0 ]]; then
    printf "%s: tests have failed\n" "$SCRIPTNAME"
    exit -1
fi

OBJECTS=$( \
    ( \
        jq -r -R "fromjson? | select(.profile.test == true) | .filenames[]" <<< $TEST_OUTPUT; \
        find target/debug -type f \( -name "$CRATE_NAME*" -or -name "$CRATE_NAME_FS_SAFE*" \) -not -name "*.d" \
    ) \
    | xargs -I {} printf "%s=%s " "-object" "{}" \
)

EXCEPTIONS=$(
    cat .llvm-cov-ignore \
    | xargs -I {} printf "%s=%s " "-ignore-filename-regex" "{}"
)

llvm-profdata merge \
    -sparse "$PROFRAW_DIR"/* \
    -o "$PROFDATA_FILE"

llvm-cov export \
    -format=lcov \
    -instr-profile="$PROFDATA_FILE" \
    -Xdemangler=rustfilt \
    $EXCEPTIONS \
    $OBJECTS \
    >"$REPORT_TEMP_FILE"

llvm-cov show \
    -format=html \
    -output-dir="$HTML_TEMP_DIR" \
    -show-instantiations=true \
    -show-mcdc=true \
    -show-regions=true \
    -show-line-counts=false \
    -show-line-counts-or-regions=false \
    -instr-profile="$PROFDATA_FILE" \
    -Xdemangler=rustfilt \
    $EXCEPTIONS \
    $OBJECTS

# copy HTML report and fix permissions
cp -r "$HTML_TEMP_DIR" "$OUTPUT_DIR"
chmod -R 755 "$OUTPUT_DIR"/*
# copy LCOV report and translate source file pathes for Sonarqube
cat "$REPORT_TEMP_FILE" | sed 's/^SF:\/app\/work/SF:./' >"$REPORT_FILE"

popd
