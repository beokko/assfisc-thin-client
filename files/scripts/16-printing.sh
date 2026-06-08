#!/usr/bin/env bash

set -xeuo pipefail

dnf install -y cups cups-filters cups-browsed ipp-usb avahi

systemctl enable cups.service avahi-daemon.service ipp-usb.service cups-browsed.service
printf 'CreateIPPPrinterQueues All\n' >> /etc/cups/cups-browsed.conf
