#!/bin/bash

set -euo pipefail

env_file="/usr/lib/env"
source "$env_file"
logfile="$HOME/.local/share/xfreerdp/xfreerdp.log"
kb_layout="0x080C"
xfreerdp_args=(
    "/v:$RDP_ENDPOINT" "/f"
    "/sound" "/smartcard" "/kbd:layout:$kb_layout"
    "/cert:tofu" "/floatbar:sticky:off,default:hidden,show:fullscreen"
)

create_logfile(){
    if [[ ! -f "$logfile" ]]; then
        mkdir -p "$(dirname "$logfile")"
        touch "$logfile"
    fi
}

log() {
    local message="$1"
    local log_line
    log_line="[$(date '+%Y-%m-%d %H:%M:%S')] $message"
    echo "$log_line" | tee -a "$logfile"
}

rotate_logfile() {
    local size
    local max_size="10485760"
    size=$(stat -c %s "$logfile" 2>/dev/null)
    if [[ "$size" -ge "$max_size" ]]; then
        rm -f "${logfile}.old"
        cp "$logfile" "${logfile}.old"
        : > "$logfile"
    fi
}

get_credentials() {
    local username password domain
    domain="${RDP_DOMAIN:-}"

    if [[ -z "$domain" ]]; then
        domain=$(kdialog --title "RDP Connection" \
            --inputbox "Domain (leave empty if not applicable):" "" 2>/dev/null) || {
            log "Credential prompt cancelled by user"
            exit 0
        }
    fi

    username=$(kdialog --title "RDP Connection" \
        --inputbox "Username:" "" 2>/dev/null) || {
        log "Credential prompt cancelled by user"
        exit 0
    }
    if [[ -z "$username" ]]; then
        kdialog --title "RDP Connection" --error "Username cannot be empty."
        exit 1
    fi

    password=$(kdialog --title "RDP Connection" \
        --password "Password for ${domain:+$domain\\}$username:" 2>/dev/null) || {
        log "Credential prompt cancelled by user"
        exit 0
    }

    CRED_DOMAIN="$domain"
    CRED_USER="$username"
    CRED_PASS="$password"
}

check_availability() {
    local attempt=0
    until ping -c1 -W5 "$RDP_ENDPOINT" &>/dev/null; do
        ((++attempt))
        if [[ $attempt -ge 60 ]]; then
            log "Could not reach endpoint after 10min, aborting"
            /usr/bin/notify-send -a xfreerdp -h "string:desktop-entry:org.kde.krdc" "xfreerdp" "Could not reach endpoint after 10min, aborting"
            exit 1
        fi
        log "Trying to reach ${RDP_ENDPOINT}..."
        sleep 5
    done
}

create_logfile
rotate_logfile
check_availability

while true; do
    get_credentials

    rdp_output=$(mktemp)
    rdp_exit=0
    set +e
    xfreerdp "${xfreerdp_args[@]}" "/d:$CRED_DOMAIN" "/u:$CRED_USER" "/p:$CRED_PASS" \
        > "$rdp_output" 2>&1
    rdp_exit=$?
    set -e
    unset CRED_PASS

    while IFS= read -r line; do log "$line"; done < "$rdp_output"

    if [[ $rdp_exit -eq 0 ]]; then
        rm -f "$rdp_output"
        break
    fi

    if grep -qE "ERRCONNECT_LOGON_FAILURE|ERRCONNECT_ACCOUNT|ERRCONNECT_PASSWORD|NLA Authentication failure" "$rdp_output"; then
        rm -f "$rdp_output"
        log "Authentication failed for user ${CRED_DOMAIN:+$CRED_DOMAIN\\}$CRED_USER"
        kdialog --title "RDP Connection" \
            --sorry "Authentication failed. Please check your credentials and try again." 2>/dev/null || true
        continue
    fi

    rm -f "$rdp_output"
    log "RDP session ended with error (exit code $rdp_exit)"
    /usr/bin/notify-send -a xfreerdp -h "string:desktop-entry:org.kde.krdc" \
        "RDP Connection" "Connection ended unexpectedly (error $rdp_exit)"
    break
done
