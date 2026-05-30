# use an Ubuntu base image
# FROM ubuntu:24.04
FROM debian:bookworm-slim

# prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# set up environment and working directories
ARG LLVM_VERSION=20
ARG APP_USER=appuser

ENV APP_HOME="/app"
ENV WORK_DIR="$APP_HOME/work"
ENV CARGO_HOME="$APP_HOME/.cargo"

ENV LD_LIBRARY_PATH="/usr/lib/llvm-$LLVM_VERSION/lib"
ENV PATH="$CARGO_HOME/bin:/usr/lib/llvm-$LLVM_VERSION/bin:$PATH"

# set PATH for interactive shell

# set up working directories
WORKDIR "$WORK_DIR"
WORKDIR "$APP_HOME"

# - install essential tools
# - install LLVM
# - clean up apt cache
# - setup non-root user
# - prepare nginx to run non-root
RUN <<EOT
    printf "export PATH=%s:$PATH" "$PATHEXT" >> /etc/bash.bashrc
    apt-get update
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        gcc-aarch64-linux-gnu \
        gcc-arm-linux-gnueabi \
        gnupg \
        jq \
        less \
        libc6-dev-arm64-cross \
        libc6-dev-armel-cross \
        libssl-dev \
        lsb-release \
        mingw-w64 \
        software-properties-common \
        vim
    curl -sSfL \
        --proto "=https" \
        https://apt.llvm.org/llvm.sh \
    | bash -s "$LLVM_VERSION"
    apt-get clean
    rm -rf \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*
    groupadd --gid 1000 $APP_USER
    useradd --uid 1000 --gid $APP_USER --shell /bin/bash --create-home $APP_USER
    chown -R $APP_USER:$APP_USER $APP_HOME
EOT

# switch to non-root user
USER $APP_USER

# Setup Rust
COPY rust-toolchain.toml rust-toolchain.toml
RUN <<EOT
    curl -sSfL \
        --proto "=https" \
        https://sh.rustup.rs \
    | bash -s -- -y
    rustup toolchain install
    rustup default
    cargo install rustfilt
EOT

# install custom scripts and other files
COPY *.sh .llvm-cov-ignore .
