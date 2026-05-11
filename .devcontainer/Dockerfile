# syntax=docker/dockerfile:1

FROM ruby:4.0.1-slim

ENV DEBIAN_FRONTEND=noninteractive \
    BUNDLE_PATH=/usr/local/bundle

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      ca-certificates \
      curl \
      git \
      libpq-dev \
      libvips \
      pkg-config \
      postgresql-client && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash vscode && \
    mkdir -p /usr/local/bundle && \
    chown -R vscode:vscode /usr/local/bundle

WORKDIR /workspaces/datawires

USER vscode
