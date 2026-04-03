#!/usr/bin/env bash

set -xeuo pipefail

# COPR for smartcard reader proprietory driver
dnf copr enable acshk/acsccid -y

dnf install -y \
    pcsc-lite-acsccid \
    pcsc-lite \
    pcsc-lite-ccid \
    opensc

systemctl enable pcscd.socket
