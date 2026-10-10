#!/bin/bash
set -xeuo pipefail
umask 077
shopt -s nullglob

source /usr/lib/env
dir="/etc/wireguard"
conf="$dir/wg0.conf"
keep=3

# A usable config has a key, a peer and no leftover provisioning placeholders.
valid() {
    [[ -s "$1" ]] \
        && grep -q '^PrivateKey = ' "$1" \
        && grep -q '^\[Peer\]' "$1" \
        && ! grep -q 'PLACEHOLDER_' "$1"
}

# Copy $1 to $2 so that $2 is either the old file or the full new one, even
# if power is lost halfway. Temp file lives in the same directory for mv.
install_atomic() {
    local tmp
    tmp=$(mktemp "$dir/.tmp.XXXXXX")
    cp "$1" "$tmp"
    sync "$tmp"
    mv -f "$tmp" "$2"
    sync "$dir"
}

mkdir -p "$dir"
chmod 700 "$dir"

# Older images kept a single wg0.conf.bak. Move it to the dated naming.
legacy="$conf.bak"
if [[ -e "$legacy" ]]; then
    if valid "$legacy"; then
        chmod 600 "$legacy"
        mv -n "$legacy" "$conf.$(date -r "$legacy" +%Y%m%d).bak"
    fi
    rm -f "$legacy"
fi

# Drop leftovers of an interrupted run and backups that are not usable.
rm -f "$dir"/.tmp.*
for b in "$conf".[0-9]*.bak; do
    valid "$b" || rm -f "$b"
done

# Restore from the newest good backup if the config is empty or broken.
if ! valid "$conf"; then
    backups=("$conf".[0-9]*.bak)
    if (( ${#backups[@]} == 0 )); then
        echo "$conf is not usable and there is no backup" >&2
        exit 1
    fi
    echo "$conf is not usable, restoring ${backups[-1]}" >&2
    install_atomic "${backups[-1]}" "$conf"
fi

# Only write when something changed.
tmp=$(mktemp "$dir/.tmp.XXXXXX")
sed \
    -e "s|^Endpoint = .*|Endpoint = ${WG_ENDPOINT}:${WG_ENDPOINT_PORT}|" \
    -e "s|^AllowedIPs = .*|AllowedIPs = ${WG_ALLOWED_IPS}|" \
    -e "s|^PersistentKeepalive = .*|PersistentKeepalive = ${WG_KEEPALIVE}|" \
    "$conf" > "$tmp"
if cmp -s "$tmp" "$conf"; then
    rm -f "$tmp"
elif valid "$tmp"; then
    sync "$tmp"
    mv -f "$tmp" "$conf"
    sync "$dir"
else
    echo "edited config is not valid, keeping the current one" >&2
    rm -f "$tmp"
fi

# Keep the last $keep distinct configs, named by the day they were saved.
backups=("$conf".[0-9]*.bak)
if (( ${#backups[@]} == 0 )) || ! cmp -s "$conf" "${backups[-1]}"; then
    install_atomic "$conf" "$conf.$(date +%Y%m%d).bak"
fi
backups=("$conf".[0-9]*.bak)
while (( ${#backups[@]} > keep )); do
    rm -f "${backups[0]}"
    backups=("${backups[@]:1}")
done
