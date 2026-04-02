#!/usr/bin/env bash

set -xeuo pipefail

dnf install -y bluez bluedevil
systemctl enable bluetooth.service

