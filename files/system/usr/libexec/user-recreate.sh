#!/bin/bash

set -xeuo pipefail

username="user"
user_display_name="Utilisateur"
persist_files=(
    ".config/kxkbrc"
    ".config/krdcrc"
    ".config/autostart/org.kde.krdc.desktop"
    ".config/freerdp"
)
persist_dir="/var/lib/user-persist"
password_hash=$(openssl rand -base64 32 | openssl passwd -6 -stdin)

# Save files to persist before deleting the user
if getent passwd "$username" > /dev/null; then
    for f in "${persist_files[@]}"; do
        src="/home/$username/$f"
        dst="$persist_dir/$f"
        if [[ -d "$src" ]]; then
            mkdir -p "$dst"
            cp -a "$src/." "$dst/"
        elif [[ -f "$src" ]]; then
            mkdir -p "$(dirname "$dst")"
            cp "$src" "$dst"
        fi
    done
    userdel -rf "$username"
fi

getent group 1000 || groupadd --gid 1000 "$username"
useradd -m -u 1000 -g 1000 -c "$user_display_name" -p "$password_hash" "$username"

# Restore persisted files
for f in "${persist_files[@]}"; do
    dst="/home/$username/$f"
    src="$persist_dir/$f"
    if [[ -d "$src" ]]; then
        mkdir -p "$dst"
        cp -a "$src/." "$dst/"
    elif [[ -f "$src" ]]; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
    fi
done
