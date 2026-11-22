#!/usr/bin/env bash
# Runs at the end of the live ISO build, inside the live environment. See
# hook-script in .github/workflows/build-iso.yml.
#
# Adjusts the live session and adds our defaults to the installer's
# kickstart. None of this ends up on the installed system, which is
# installed from the image itself.

set -euo pipefail

systemctl disable \
    first-boot-provision.service \
    selinux-relabel.service \
    user-recreate.service

rm -f /etc/skel/.config/autostart/org.kde.krdc.desktop

mv -f /usr/bin/konsole.real /usr/bin/konsole
chown root:root /usr/bin/konsole
chmod 755 /usr/bin/konsole

# The installer is interactive, these only pre-fill its choices. It asks for
# the disk passphrase itself.

cat >> /usr/share/anaconda/interactive-defaults.ks <<'EOF'

lang fr_BE.UTF-8
keyboard --vckeymap=be-latin1 --xlayouts='fr'
timezone Europe/Brussels

firewall --use-system-defaults

zerombr
clearpart --all --initlabel --disklabel=gpt
autopart --type=lvm --encrypted --luks-version=luks2

rootpw --lock
EOF
