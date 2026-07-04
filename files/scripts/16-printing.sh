#!/usr/bin/env bash

set -xeuo pipefail

dnf install -y cups cups-filters cups-browsed cups-printerapp avahi-tools ipp-usb avahi

systemctl enable cups.service avahi-daemon.service cups-browsed.service

mv /etc/cups/cups-browsed.conf /etc/cups/cups-browsed.conf.original

# The comment line is to make sure cups-browsed's install scriptlet can never ever overwrite this in the unlikely case the package gets updated after this step.
cat > /etc/cups/cups-browsed.conf << EOF
# added by post scriptlet
BrowseRemoteProtocols dnssd
CreateIPPPrinterQueues LocalOnly
OnlyUnsupportedByCUPS No
AutoShutdown Off
EOF
