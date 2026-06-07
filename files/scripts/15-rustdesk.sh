#!/usr/bin/env bash

set -xeuo pipefail

tmpdir=$(mktemp -d)
pwd=$(pwd)
cd "$tmpdir"

rustdesk_ver="1.4.7"
rustdesk_sha256="5b18f2d32ebd9d990546746c46c5ffcea0852bf1eda963497da15651e83d5f20"
rustdesk_url="https://github.com/rustdesk/rustdesk/releases/download/$rustdesk_ver/rustdesk-$rustdesk_ver-0.x86_64.rpm"
curl -sSL "$rustdesk_url" -o rustdesk.rpm
echo "$rustdesk_sha256  rustdesk.rpm" | sha256sum --check

dnf install -y ./rustdesk.rpm pipewire-gstreamer

cd "$pwd"
rm -rf "$tmpdir"

systemctl disable rustdesk.service
