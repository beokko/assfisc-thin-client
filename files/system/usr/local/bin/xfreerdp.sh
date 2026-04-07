#!/bin/bash

set -euo pipefail

env_file="/usr/lib/env"
source "$env_file"
logfile="$HOME/.local/share/xfreerdp/xfreerdp.log"
kb_layout="0x080C"
xfreerdp_args=(
    "/v:$RDP_ENDPOINT" "/d:" "/u:" "/p:" "/f"
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
while IFS= read -r line; do
    log "$line"
done < <(xfreerdp "${xfreerdp_args[@]}" 2>&1)
