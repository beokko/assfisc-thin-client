#!/usr/bin/env bash
# Runs at the end of the live ISO build, inside the live environment. See
# hook-script in .github/workflows/build-iso.yml.
#
# Adds our defaults to the installer's kickstart. The installer is still
# interactive, these only pre-fill its choices. CI replaces PLACEHOLDER
# with the LUKS_PLACEHOLDER_PASS secret before the build.

set -euo pipefail

systemctl disable \
    first-boot-provision.service \
    selinux-relabel.service \
    user-recreate.service

cat >> /usr/share/anaconda/interactive-defaults.ks <<'EOF'

lang fr_BE.UTF-8
keyboard --vckeymap=be-latin1 --xlayouts='fr'
timezone Europe/Brussels

firewall --use-system-defaults

rootpw --lock
EOF
