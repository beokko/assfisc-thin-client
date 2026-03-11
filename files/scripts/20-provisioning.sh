#!/bin/bash

set -xeuo pipefail

chmod 700 /usr/libexec/first-boot-provision.sh
chmod 755 /usr/libexec/user-recreate.sh
chown root:root /usr/libexec/first-boot-provision.sh
chown root:root /usr/libexec/user-recreate.sh

chmod 700 /etc/wireguard
chmod 600 /etc/wireguard/wg0.conf

systemctl enable first-boot-provision.service
systemctl enable user-recreate.service
