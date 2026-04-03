#!/usr/bin/env bash

set -xeuo pipefail

# KDE minimal
dnf install -y --setopt=group_package_types=mandatory @"KDE"

# Other needed packages
dnf install -y \
    glibc-langpack-fr \
    plymouth \
    plymouth-system-theme \
    kde-settings \
    kscreen \
    NetworkManager \
    NetworkManager-wifi \
    plasma-nm \
    krdc \
    wireguard-tools \
    qrencode \
    firewalld \
    konsole \
    xorg-x11-xauth \
    freerdp 

# Unnecessary things
dnf remove -y \
    nfs-utils \
    quota \
    rpcbind \
    cloud-utils-growpart \
    WALinuxAgent-udev \
    kdump-utils \
    kexec-tools \
    makedumpfile \
    PackageKit \
    qt6-qtwebengine \
    ghostscript \
    libgs \
    toolbox \
    sos \
    usbmuxd \
    plasma-welcome \
    tracker \
    xwaylandvideobridge

# TZ
ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime

# Change konsole's perms and ownership
chown root:wheel /usr/bin/konsole
chmod 750 /usr/bin/konsole
