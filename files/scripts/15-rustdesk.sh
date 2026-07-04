#!/usr/bin/env bash

set -xeuo pipefail

tmpdir=$(mktemp -d)
pwd=$(pwd)
cd "$tmpdir"

rustdesk_ver="1.4.8"
rustdesk_sha256="2a62c6009cada96237739f92d57579987d260b7b81011b95876cca6dce1bf616"
rustdesk_url="https://github.com/rustdesk/rustdesk/releases/download/$rustdesk_ver/rustdesk-$rustdesk_ver-0.x86_64.rpm"
curl -sSL "$rustdesk_url" -o rustdesk.rpm
echo "$rustdesk_sha256  rustdesk.rpm" | sha256sum --check

dnf install -y ./rustdesk.rpm pipewire-gstreamer

cd "$pwd"
rm -rf "$tmpdir"

systemctl disable rustdesk.service
