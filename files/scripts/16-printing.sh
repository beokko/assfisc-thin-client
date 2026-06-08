#!/usr/bin/env bash

set -xeuo pipefail

dnf install -y cups cups-filters cups-browsed cups-printerapp avahi-tools ipp-usb avahi

systemctl enable cups.service avahi-daemon.service cups-browsed.service
printf 'CreateIPPPrinterQueues All\n' >> /etc/cups/cups-browsed.conf
