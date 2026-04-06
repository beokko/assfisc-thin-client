#!/bin/bash

set -euo pipefail

source /usr/lib/env

kb_layout="0x080C"
xfreerdp_args=(
    "/v:$RDP_ENDPOINT" "/d:" "/u:" "/p:" "/f"
    "/sound" "/smartcard" "/kbd:layout:$kb_layout"
    "/cert:tofu" "/floatbar:sticky:off,default:hidden,show:fullscreen"
)

attempt=0
until ping -c1 -W5 "$RDP_ENDPOINT" &>/dev/null; do
    ((++attempt))
    if [[ $attempt -ge 120 ]]; then
        /usr/bin/notify-send -a xfreerdp -h "string:desktop-entry:org.kde.krdc" "xfreerdp" "Could not reach endpoint after 10min, aborting"
        exit 1
    fi
    sleep 5
done

xfreerdp "${xfreerdp_args[@]}"
