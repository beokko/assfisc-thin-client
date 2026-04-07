#!/bin/bash
set -xeuo pipefail

source /usr/lib/env
conf="/etc/wireguard/wg0.conf"

mkdir -p "$(dirname "$conf")"
[[ -f "${conf}.bak" ]] || cp "$conf" "${conf}.bak"

sed -i \
    -e "s|^Endpoint = .*|Endpoint = ${WG_ENDPOINT}:${WG_ENDPOINT_PORT}|" \
    -e "s|^AllowedIPs = .*|AllowedIPs = ${WG_ALLOWED_IPS}|" \
    -e "s|^PersistentKeepalive = .*|PersistentKeepalive = ${WG_KEEPALIVE}|" \
    "$conf"
