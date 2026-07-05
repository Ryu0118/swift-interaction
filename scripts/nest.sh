#!/bin/bash
set -euo pipefail

SRCROOT=$(git rev-parse --show-toplevel)

# Pin the third-party installer to a specific release tag rather than `main`,
# so `make install-commands` (and CI) always run a known revision of this
# supply-chain dependency instead of whatever is on that repo's default branch
# at the moment. Bump deliberately when adopting a new nest release.
NEST_VERSION="0.7.1"

if [ ! -d "$HOME/.nest/bin" ] || [ ! -f "$HOME/.nest/bin/nest" ]; then
    echo "nest command not found globally or locally. Installing nest ${NEST_VERSION}..."
    curl -sSf "https://raw.githubusercontent.com/mtj0928/nest/${NEST_VERSION}/Scripts/install.sh" | bash

    if [ ! -d "$HOME/.nest/bin" ] || [ ! -f "$HOME/.nest/bin/nest" ]; then
        echo "Failed to install nest command. Please install it manually."
        exit 1
    fi
    echo "nest installed successfully!"

    "$HOME/.nest/bin/nest" bootstrap "$SRCROOT/nestfile.yaml"
fi

"$HOME/.nest/bin/nest" "$@"
