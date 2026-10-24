FROM ubuntu:latest as devpod

# Version
ARG DEVPOD_VERSION
LABEL org.opencontainers.image.version="${DEVPOD_VERSION}"
RUN echo "devpod container version ${DEVPOD_VERSION}"

RUN apt-get update && apt-get install -y \
    bash \
    build-essential \
    ca-certificates \
    curl \
    fd-find \
    file \
    fzf \
    git \
    gnupg \
    imagemagick \
    jq \
    less \
    libpam0g-dev \
    lsb-release \
    lsof \
    procps \
    ripgrep \
    sudo \
    tar \
    tmux \
    tree \
    unzip \
    vim \
    wget \
    zip \
    zstd \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.config/opencode && \
    mkdir -p /root/.local/share/opencode && \
    mkdir -p /root/.cache/opencode && \
    mkdir -p /root/.config/openspec && \
    mkdir -p /root/.local/bin && \
    mkdir -p /root/.npm

COPY bashrc /root/.bashrc

RUN git config --global user.name "Diego Cortassa"
RUN git config --global user.email "diego@cortassa.net"

RUN curl -sS https://starship.rs/install.sh | sh -s -- -y > /dev/null
COPY starship.toml /root/.config/starship.toml

# Node.js
ENV NODE_MAJOR=24
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list
RUN apt-get update && apt-get install -y nodejs && \
    node --version && \
    npm --version && \
    rm -rf /var/lib/apt/lists/*
ENV NPM_CONFIG_PREFIX=/root/.npm-global
ENV PATH=/root/.npm-global/bin:$PATH
RUN mkdir -p /root/.npm-global

# Go
ENV GO_VERSION=1.27.3
ENV GO_HOME=/root/.local/bin/go
ENV PATH=$GO_HOME/bin:$PATH
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | \
    tar -C /root/.local/bin -xzf -

# Rust
#RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
ENV PATH="/root/.cargo/bin:${PATH}"
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

# Python uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Modify this and rebuild image to get the latest opencode
RUN echo "1.9.4"
RUN npm i -g opencode-ai

CMD ["/bin/bash"]
