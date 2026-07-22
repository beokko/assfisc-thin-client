#!/usr/bin/env bash

set -xeuo pipefail

# KDE minimal
dnf install -y --setopt=group_package_types=mandatory @"KDE"

# Unnecessary things
dnf remove -y \
    plasma-login-manager \
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
    toolbox \
    sos \
    usbmuxd \
    plasma-welcome \
    tracker \
    xwaylandvideobridge

# Other needed packages
dnf install -y \
    sddm \
    kde-settings-sddm \
    sddm-breeze \
    sddm-kcm \
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
    freerdp \
    kdialog

# Disable plasmalogin, enable sddm
systemctl disable plasmalogin.service || true
systemctl enable sddm.service

# TZ
ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime

# Change konsole's perms and ownership
chown root:wheel /usr/bin/konsole
chmod 750 /usr/bin/konsole

# Auto-launches xfreerdp script at user login
mkdir -p /etc/skel/.config/autostart
ln -sf /usr/local/share/applications/org.kde.krdc.desktop /etc/skel/.config/autostart/org.kde.krdc.desktop
chmod +x /usr/local/bin/xfreerdp.sh

# Copy ghcr pull token, if applicable
if [[ -f /run/secrets/auth.json && -s /run/secrets/auth.json ]]; then
    install -Dm0600 /run/secrets/auth.json /usr/lib/ostree/auth.json
fi

chmod +x /usr/libexec/wg-recreate.sh
systemctl enable wg-recreate.service
