#!/bin/bash

set -xeuo pipefail

chmod 700 /usr/libexec/first-boot-provision.sh
chown root:root /usr/libexec/first-boot-provision.sh

chmod 700 /etc/wireguard
chmod 600 /etc/wireguard/wg0.conf

systemctl enable first-boot-provision.service