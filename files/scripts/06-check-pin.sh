#!/usr/bin/env bash

set -xeuo pipefail

# Every enabled repo must resolve to the release we pinned in
# 02-pin-releasever.sh. Runs after 05-epel.sh so EPEL is covered too.
pin="$(cat /etc/dnf/vars/releasever)"

urls="$(dnf repolist --enabled -v | grep -E '^\s*Repo-(baseurl|mirrors|metalink)\s*:' || true)"
printf '%s\n' "$urls"

if [ -z "$urls" ]; then
    echo "ERROR: could not find any repository URL to check"
    exit 1
fi

re="(^|[^0-9.])${pin//./\\.}([^0-9]|$)"

if printf '%s\n' "$urls" | grep -vE "$re"; then
    echo "ERROR: some repositories do not point at release $pin"
    exit 1
fi
