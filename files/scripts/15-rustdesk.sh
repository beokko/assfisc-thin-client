#!/usr/bin/env bash

set -xeuo pipefail

tmpdir=$(mktemp -d)
pwd=$(pwd)
cd "$tmpdir"

rustdesk_ver="1.4.6"
rustdesk_url="https://github.com/rustdesk/rustdesk/releases/download/$rustdesk_ver/rustdesk-$rustdesk_ver-0.x86_64.rpm"

curl -sSL "$rustdesk_url" -o rustdesk.rpm

dnf install -y ./rustdesk.rpm pipewire-gstreamer

cd "$pwd"
rm -rf "$tmpdir"

systemctl disable rustdesk.service
