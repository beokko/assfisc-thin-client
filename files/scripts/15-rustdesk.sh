#!/usr/bin/env bash

set -xeuo pipefail

tmpdir=$(mktemp -d)
pwd=$(pwd)
cd "$tmpdir"

rustdesk_ver="1.4.9"
rustdesk_sha256="eb1b053ac5b2f774f2271f7fbbfd2ea475899f7a55135c5e172bc54b9388f108"
rustdesk_url="https://github.com/rustdesk/rustdesk/releases/download/$rustdesk_ver/rustdesk-$rustdesk_ver-0.x86_64.rpm"
curl -sSL "$rustdesk_url" -o rustdesk.rpm
echo "$rustdesk_sha256  rustdesk.rpm" | sha256sum --check

dnf install -y ./rustdesk.rpm pipewire-gstreamer

cd "$pwd"
rm -rf "$tmpdir"

systemctl disable rustdesk.service
