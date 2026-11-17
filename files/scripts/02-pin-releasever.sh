#!/usr/bin/env bash

set -xeuo pipefail

# The AlmaLinux and EPEL repo files use $releasever, which is just "10" and
# follows the latest minor release. Pin it so every dnf call in the build
# stays on the same minor release as the base image.
# 06-check-pin.sh verifies the result once EPEL is set up.
mkdir -p /etc/dnf/vars
. /etc/os-release
echo "$VERSION_ID" > /etc/dnf/vars/releasever
