#!/usr/bin/env bash

set -xeuo pipefail

# Printing
systemctl mask cups.service cups.socket cups-browsed.service

# mDNS (Avahi)
systemctl mask avahi-daemon.service avahi-daemon.socket

# Modem Manager (no mobile modems on thin client)
systemctl mask ModemManager.service

# Crash/debug reporting (ABRT)
systemctl mask abrtd.service abrt-oops.service abrt-xorg.service abrt-journal-core.service

# Core dumps
systemctl mask systemd-coredump.socket

# Avoid blocking boot when WireGuard VPN isn't up yet
systemctl mask NetworkManager-wait-online.service

# TTYs 2-6: tty1 is used for first-boot provisioning, tty7+ for the display server
systemctl mask \
    getty@tty2.service \
    getty@tty3.service \
    getty@tty4.service \
    getty@tty5.service \
    getty@tty6.service

# systemctl mask sshd