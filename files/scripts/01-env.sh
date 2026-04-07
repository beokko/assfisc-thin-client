#!/usr/bin/env bash

set -xeuo pipefail

CONTEXT_PATH="$(realpath "$(dirname "$0")/..")" # should return /ctx

if [ ! -f "${CONTEXT_PATH}/env" ]; then
    echo "ERROR: Environment file not found"
    exit 1
fi

cp "${CONTEXT_PATH}/env" /usr/lib/env
