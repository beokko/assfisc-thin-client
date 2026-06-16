#!/usr/bin/env bash

set -xeuo pipefail

dnf install -y kernel-devel kernel-headers gcc make git bc dkms

git clone https://github.com/lwfinger/rtw88.git /tmp/rtw88
cd /tmp/rtw88

# This is janky as hell and could break on any update. Good luck
sed -i -E 's/KERNEL_VERSION\(6, 1[3-7], 0\)/KERNEL_VERSION(6, 12, 0)/g' *.c *.h

if [[ ! -f /etc/pki/dkms/mok.pub || ! -f /run/secrets/mok.key ]]; then
    echo "ERROR: MOK cert or key missing"
    exit 1
fi
mkdir -p /var/lib/dkms
cp /run/secrets/mok.key /var/lib/dkms/mok.key
cp /etc/pki/dkms/mok.pub /var/lib/dkms/mok.pub

kver=$(cd /usr/lib/modules && echo *)
dkms install "$PWD" -k "$kver" --kernelsourcedir "/usr/src/kernels/$kver"
make install_fw KVER="$kver"

cp rtw88.conf /etc/modprobe.d/
echo "rtw_8723du" > /etc/modules-load.d/rtw88-8723du.conf

rm -rf /tmp/rtw88
