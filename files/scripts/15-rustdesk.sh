#!/usr/bin/env bash

set -xeuo pipefail

tmpdir=$(mktemp -d)
pwd=$(pwd)
cd "$tmpdir"

rustdesk_ver="1.5.0"
rustdesk_sha256="96e4246d62a992630dacac3472f356ad517a5ef6d0cd8ea02b5648bc1cabff26"
rustdesk_url="https://github.com/rustdesk/rustdesk/releases/download/$rustdesk_ver/rustdesk-$rustdesk_ver-0.x86_64.rpm"
curl -sSL "$rustdesk_url" -o rustdesk.rpm
echo "$rustdesk_sha256  rustdesk.rpm" | sha256sum --check

dnf install -y ./rustdesk.rpm pipewire-gstreamer

cd "$pwd"
rm -rf "$tmpdir"

systemctl disable rustdesk.service
