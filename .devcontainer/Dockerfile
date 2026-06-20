FROM mcr.microsoft.com/devcontainers/base:ubuntu

ARG RUBY_VERSION=4.0.1

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    ca-certificates \
    postgresql-client \
    libssl-dev \
    libyaml-dev \
    zlib1g-dev \
    libreadline-dev \
    libncurses5-dev \
    libffi-dev \
    libgdbm-dev \
    rustc \
    cargo \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/rbenv/rbenv.git /usr/local/rbenv \
    && git clone https://github.com/rbenv/ruby-build.git /usr/local/rbenv/plugins/ruby-build

ENV RBENV_ROOT=/usr/local/rbenv
ENV PATH=/usr/local/rbenv/bin:/usr/local/rbenv/shims:$PATH

RUN /usr/local/rbenv/bin/rbenv install ${RUBY_VERSION} \
    && /usr/local/rbenv/bin/rbenv global ${RUBY_VERSION} \
    && gem install bundler

RUN mkdir -p /usr/local/bundle \
    && chown -R vscode:vscode /usr/local/rbenv /usr/local/bundle

USER vscode
WORKDIR /workspaces/datawires
