# use an Ubuntu base image
FROM ubuntu:24.04

# prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# set up environment and working directories
ENV APP_HOME="/app"
ENV WORK_DIR="$APP_HOME/work"
ENV CARGO_HOME="$APP_HOME/.cargo"

ENV LLVM_VERSION=20
ENV LD_LIBRARY_PATH="/usr/lib/llvm-$LLVM_VERSION/lib"
ENV PATHEXT="$CARGO_HOME/bin:/usr/lib/llvm-$LLVM_VERSION/bin"
ENV PATH="$PATHEXT:$PATH"

# set PATH for interactive shell

# set up working directories
WORKDIR "$WORK_DIR"
WORKDIR "$APP_HOME"

# - install essential tools
# - install LLVM
# - clean up apt cache
# - setup non-root user
# - prepare nginx to run non-root
RUN printf "export PATH=%s:$PATH" "$PATHEXT" >> /etc/bash.bashrc \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
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
        vim \
    && curl --proto "=https" -sSf -L https://apt.llvm.org/llvm.sh | bash -s "$LLVM_VERSION" \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/* \
    && chown -R ubuntu:ubuntu $APP_HOME

# switch to non-root user
USER ubuntu

# Setup Rust
COPY rust-toolchain.toml rust-toolchain.toml
RUN curl --proto "=https" -sSf https://sh.rustup.rs | bash -s -- -y \
    && rustup toolchain install \
    && rustup default \
    && cargo install rustfilt

# install custom scripts
COPY *.sh .
