#!/bin/bash

set -euo pipefail

cleanup() {
    [[ -f /var/lib/first-boot-provisioned ]] && return

    echo ""
    echo "========================================"
    echo "  Provisioning failed or was interrupted"
    echo "========================================"

    if id admin &>/dev/null; then
        echo "Removing user 'admin'..."
        userdel -r admin 2>/dev/null || true
        groupdel admin 2>/dev/null || true
    fi

    if [[ -n "${username:-}" ]]; then
        echo "Removing user '${username}'..."
        userdel -r "$username" 2>/dev/null || true
        groupdel "$username" 2>/dev/null || true
    fi

    [[ -n "${cred_dir:-}" && -d "$cred_dir" ]] && rm -rf "$cred_dir"

    echo "Provisioning will retry on next boot."
}

trap cleanup EXIT

setfont sun12x22

# --- Hostname ---
primary_iface=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
mac=$(cat "/sys/class/net/${primary_iface}/address" 2>/dev/null \
      || ip link show | awk '/ether/ {print $2; exit}')
mac_suffix=${mac//:/}
mac_suffix=${mac_suffix: -6}
machine_hostname="assfisc-client-${mac_suffix}"
hostnamectl set-hostname "$machine_hostname"
echo "Hostname set to: $machine_hostname"
unset primary_iface mac mac_suffix machine_hostname

# --- Admin provisioning ---
while true; do
    echo
    read -r -s -p "Enter desired admin password: " admin_password
    echo
    read -r -s -p "Confirm admin password: " admin_password_confirm
    echo
    if [[ "$admin_password" != "$admin_password_confirm" ]]; then
        echo "Passwords do not match, try again."
        continue
    fi
    if [[ ${#admin_password} -ge 8 ]]; then
        break
    else
        echo "Password must be at least 8 characters."
    fi
done

admin_hashed_password=$(echo "$admin_password" | openssl passwd -6 -stdin)
groupadd --gid 1001 admin
useradd -u 1001 -g 1001 -G wheel -p "$admin_hashed_password" admin
unset admin_password admin_password_confirm admin_hashed_password
chmod 600 /home/admin/.ssh/authorized_keys

# --- User provisioning ---
username="user"
user_display_name="Utilisateur"
password_hash=$(openssl rand -base64 32 | openssl passwd -6 -stdin) # random password, unused
groupadd --gid 1000 "$username"
useradd -m -u 1000 -g 1000 -c "$user_display_name" -p "$password_hash" "$username"

# Autologin
mkdir -p /etc/sddm.conf.d
printf "[Autologin]\nUser=%s\nSession=plasma\nRelogin=true\n" "$username" > /etc/sddm.conf.d/autologin.conf

# --- LUKS reencryption ---
echo ""
echo "========================================"
echo "       LUKS Encryption Provisioning"
echo "========================================"
echo ""

luks_device=$(blkid -t TYPE=crypto_LUKS -o device 2>/dev/null | head -1 || true)

if [[ -z "$luks_device" ]]; then
    echo "FATAL: no LUKS device found!"
    echo "This is never expected nor normal. You should reinstall."
    read -r -p "Press Enter to exit"
    exit 1
fi
echo "LUKS device: $luks_device"
echo ""

luks_dump=$(cryptsetup luksDump --dump-json-metadata "$luks_device")
keyslot_salts=$(echo "$luks_dump" | jq '.keyslots[] | .kdf.salt')
if [[ $(echo "$keyslot_salts" | wc -l) -gt 1 ]]; then 
    echo "FATAL: there are multiple keys!"
    echo "This is never expected nor normal. You should reinstall."
    read -r -p "Press Enter to exit"
    exit 1
fi
original_keyslot_salt="$keyslot_salts" # At that point there should only be one salt in the list

while true; do
    read -r -s -p "Enter current disk enrollment passphrase: " original_passphrase
    echo ""
    if printf '%s' "$original_passphrase" \
           | cryptsetup open --test-passphrase --batch-mode "$luks_device" 2>/dev/null; then
       echo "Passphrase verified."
       break
    else
       echo "Error: incorrect passphrase."
    fi
done

while true; do
    echo
    read -r -s -p "New passphrase: " passphrase
    echo
    if [[ ${#passphrase} -lt 8 ]]; then
        echo "Passphrase must be at least 8 characters."
        continue
    fi
    read -r -s -p "Confirm new passphrase: " passphrase_confirm
    echo
    [[ "$passphrase" == "$passphrase_confirm" ]] && break
    echo "passphrases do not match. Try again."
done

recovery_key=$(set +o pipefail; head -c 1024 /dev/urandom | tr -dc 'A-Z0-9' | head -c 40 | fold -w5 | paste -sd'-')

echo "Adding recovery key to keyslot..."
printf '%s' "$recovery_key" \
    | cryptsetup luksAddKey \
        --batch-mode \
        --key-file <(printf '%s' "$original_passphrase") \
        "$luks_device"

clear
echo "========================================"
echo "   RECOVERY KEY - store this safely:"
echo "========================================"
echo ""
echo "$recovery_key"
echo ""
qrencode -t UTF8 "$recovery_key"
echo ""
read -r -p "Press Enter to continue..."
clear

echo "Removing original enrollment passphrase..."
printf '%s' "$original_passphrase" \
    | cryptsetup luksRemoveKey --batch-mode "$luks_device"
unset original_passphrase

echo
if systemd-cryptenroll --tpm2-device=list 2>/dev/null | grep -q "/dev/"; then
    echo "TPM2 detected. Enrolling disk unlock via TPM2 + PIN."

    cred_dir=$(mktemp -d)
    chmod 700 "$cred_dir"
    printf '%s' "$recovery_key" > "$cred_dir/cryptenroll.passphrase"
    printf '%s' "$passphrase" > "$cred_dir/cryptenroll.new-tpm2-pin"

    CREDENTIALS_DIRECTORY="$cred_dir" systemd-cryptenroll \
        --tpm2-device=auto \
        --tpm2-pcrs=7 \
        --tpm2-with-pin=yes \
        "$luks_device"

    rm -rf "$cred_dir"

    echo
    echo "At each boot you will be prompted for the TPM PIN (passphrase)."
    echo "The recovery key unlocks the disk if the TPM is unavailable."
    echo

    echo
    if mokutil --sb-state 2>/dev/null | grep -iq 'secureboot enabled'; then
        echo "SecureBoot enabled!"
        echo "Make sure your UEFI firmware is password-protected"
    else
        echo "WARNING: SecureBoot is disabled (or in setup mode)!"
        echo "You should enable it in UEFI before using this device."
        echo "Additionally, make sure your UEFI firmware is password-protected."
    fi
    read -r -p "Press Enter to acknowledge..."
else
    echo "No TPM2 detected. Adding new passphrase as LUKS keyslot..."

    printf '%s' "$passphrase" | cryptsetup luksAddKey \
        --batch-mode \
        --key-file=<(printf '%s' "$recovery_key") \
        "$luks_device"
fi

unset recovery_key passphrase passphrase_confirm

luks_dump=$(cryptsetup luksDump --dump-json-metadata "$luks_device")
keyslot_salts=$(echo "$luks_dump" | jq '.keyslots[] | .kdf.salt')
if [[ $keyslot_salts == *"$original_keyslot_salt"* ]]; then
    echo "FATAL! The original placeholder passphrase is still present!"
    echo "This is never expected nor normal. You should reinstall."
    read -r -p "Press Enter to exit"
    exit 1
fi

echo
echo "LUKS setup done."
read -r -p "Press Enter to continue..."

# --- WireGuard ---
clear
echo "========================================"
echo "          WireGuard Provisioning"
echo "========================================"
echo ""
chmod 700 /etc/wireguard

private_key=$(wg genkey)
public_key=$(printf '%s' "$private_key" | wg pubkey)
preshared_key=$(wg genpsk)

echo "========================================"
echo "  WIREGUARD PUBLIC KEY - add to server:"
echo "========================================"
echo ""
echo "$public_key"
echo ""
qrencode -t UTF8 "$public_key"
echo ""
unset public_key

read -r -p "Press Enter once the public key has been registered on the server..."

echo ""
echo "========================================"
echo "  WIREGUARD PRE-SHARED KEY - add to server peer entry:"
echo "========================================"
echo ""
echo "$preshared_key"
echo ""
qrencode -t UTF8 "$preshared_key"
echo ""

read -r -p "Press Enter once the pre-shared key has been registered on the server..."
clear

echo "========================================"
echo "       WireGuard Client Configuration"
echo "========================================"
echo ""
while true; do
    read -r -p "This device's WireGuard address (CIDR, e.g. 10.100.0.2/24): " wg_client_address
    [[ "$wg_client_address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]] && break
    echo "Invalid format. Use IP/prefix notation (e.g. 10.100.0.2/24)."
done

while true; do
    read -r -p "WireGuard server endpoint (host:port, e.g. vpn.example.com:51820): " server_endpoint
    [[ "$server_endpoint" =~ ^[^:]+:[0-9]+$ ]] && break
    echo "Invalid format. Use host:port notation (e.g. vpn.example.com:51820)."
done

while true; do
    read -r -p "WireGuard AllowedIPs (CIDR, e.g. 10.8.0.0/24): " allowed_ips
    [[ "$allowed_ips" =~ ^[0-9./]+(,[0-9./]+)*$ ]] && break
    echo "Invalid format. Use CIDR notation (e.g. 10.8.0.0/24)."
done

sed -i \
    -e "s|PLACEHOLDER_PRIVATE_KEY|${private_key}|" \
    -e "s|PLACEHOLDER_CLIENT_ADDRESS|${wg_client_address}|" \
    -e "s|PLACEHOLDER_PRESHARED_KEY|${preshared_key}|" \
    -e "s|PLACEHOLDER_WG_ENDPOINT|${server_endpoint}|" \
    -e "s|PLACEHOLDER_WG_ALLOWEDIPS|${allowed_ips}|" \
    /etc/wireguard/wg0.conf
chmod 600 /etc/wireguard/wg0.conf
systemctl enable wg-quick@wg0.service

unset private_key preshared_key wg_client_address server_endpoint allowed_ips

# --- RDP ---
clear
echo "========================================"
echo "          RDP Configuration"
echo "========================================"
echo ""
read -r -p "RDP server endpoint (host or host:port): " rdp_endpoint

user_config="/home/${username}/.config"
sed -i "s|PLACEHOLDER_RDP_ENDPOINT|${rdp_endpoint}|g" "${user_config}/krdcrc"
sed -i "s|PLACEHOLDER_RDP_ENDPOINT|${rdp_endpoint}|g" "${user_config}/autostart/org.kde.krdc.desktop"

unset rdp_endpoint user_config

touch /var/lib/first-boot-provisioned

echo ""
echo "Provisioning complete."
read -r -p "Press Enter to reboot..."
