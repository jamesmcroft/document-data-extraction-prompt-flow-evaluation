#!/usr/bin/env bash

USERNAME=${USERNAME:-"vscode"}

set -eux

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

sudo_if() {
    COMMAND="$*"
    if [ "$(id -u)" -eq 0 ] && [ "$USERNAME" != "root" ]; then
        su - "$USERNAME" -c "$COMMAND"
    else
        "$COMMAND"
    fi
}

install_azcli_extension() {
    EXTENSION_NAME=$1

    sudo_if "az extension add -n $EXTENSION_NAME"
    sudo_if "az extension update -n $EXTENSION_NAME"
}

# Install the Azure CLI Machine Learning extension
install_azcli_extension ml

# Register the Bash Kernel with Jupyter
sudo_if "python3 -m bash_kernel.install"
