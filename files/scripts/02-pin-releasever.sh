#!/usr/bin/env bash

set -xeuo pipefail

# The AlmaLinux and EPEL repo files use $releasever, which is just "10" and
# follows the latest minor release. Pin it so every dnf call in the build
# stays on the same minor release as the base image.
mkdir -p /etc/dnf/vars
echo 10.2 > /etc/dnf/vars/releasever

# Fail early if the pin is not honoured
dnf repolist --enabled -v | grep -E 'baseurl|mirrorlist|metalink|Repo-' || true
if dnf repolist --enabled -v | grep -q '10\.3'; then
    echo "ERROR: repositories still point at 10.3"
    exit 1
fi
