#!/usr/bin/env bash

set -xeuo pipefail

firewall-offline-cmd --set-default-zone=drop
# firewall-offline-cmd --zone=drop --remove-service=ssh

systemctl enable firewalld.service