# Use a base image that supports Python.
FROM mcr.microsoft.com/vscode/devcontainers/python:1-3.12-bullseye

# Install Python dependencies
COPY requirements.txt /tmp/pip-tmp/
RUN pip3 --disable-pip-version-check --no-cache-dir install -r /tmp/pip-tmp/requirements.txt \
    && rm -rf /tmp/pip-tmp

# Install additional tools and dependencies
RUN apt-get update \
    && apt-get upgrade -y \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends unzip jq poppler-utils

# Install yq
RUN wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.25.1/yq_linux_amd64" \
    && chmod +x /usr/local/bin/yq

# Default to bash shell
ENV SHELL=/bin/bash \
    DOCKER_BUILDKIT=1

# Mount for docker-in-docker 
VOLUME [ "/var/lib/docker" ]
