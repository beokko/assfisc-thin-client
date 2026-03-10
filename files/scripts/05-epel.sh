#!/usr/bin/env bash

set -xeuo pipefail

# EPEL
dnf install -y 'dnf-command(config-manager)' epel-release
dnf config-manager --set-enabled crb
dnf upgrade -y $(dnf repoquery --installed --qf '%{name}' --whatprovides epel-release)
