# ba0fde3d-bee7-4307-b97b-17d0d20aff50
SUDO = sudo
PODMAN = $(SUDO) podman

IMAGE_NAME ?= localhost/bootc-images/alma
CONTAINER_FILE ?= ./Dockerfile
VARIANT ?= kde
IMAGE_CONFIG ?= ./iso.toml

IMAGE_TYPE ?= iso
QEMU_DISK_RAW ?= ./output/disk.raw
QEMU_DISK_QCOW2 ?= ./output/qcow2/disk.qcow2
QEMU_ISO ?= ./output/bootiso/install.iso
LIBVIRT_DOMAIN ?= 1-bootc-alma
LIBVIRT_ROOT ?= /mnt/btrfs_root/kvm
LIBVIRT_QCOW2 ?= $(LIBVIRT_ROOT)/virt-disks/$(LIBVIRT_DOMAIN).qcow2
LIBVIRT_ISO ?= $(LIBVIRT_ROOT)/iso/bootc-alma-amd64.iso

.ONESHELL:

clean:
	$(SUDO) rm -rf ./output

image:
	# This is just to make sure I have a successful sudo before I run sed
	$(SUDO) echo

	sed -i 's|AllowedIPs = GH_SEC_WG_ALLOWEDIPS|AllowedIPs = 10.8.0.0/24|' ./files/system/etc/wireguard/wg0.conf
	sed -i 's|PublicKey = GH_SEC_WG_PUBLIC_KEY|PublicKey = /s8cFxU/uc2B9wonFTySaznAjyM5Vtlhs0JY+KnKFww=|' ./files/system/etc/wireguard/wg0.conf
	sed -i 's|Endpoint = GH_SEC_WG_ENDPOINT|Endpoint = wg.placeholder.com:51820|' ./files/system/etc/wireguard/wg0.conf
	sed -i 's|GH_SEC_RDP_ENDPOINT|rdp.placeholder.com|' ./files/system/etc/skel/.config/autostart/org.kde.krdc.desktop
	sed -i 's|GH_SEC_RDP_ENDPOINT|rdp.placeholder.com|' ./files/system/etc/skel/.config/krdcrc
	
	$(PODMAN) build \
		--security-opt=label=disable \
		--cap-add=all \
		--device /dev/fuse \
		--build-arg IMAGE_NAME=$(IMAGE_NAME) \
		--build-arg IMAGE_REGISTRY=localhost \
		--build-arg VARIANT=$(VARIANT) \
		-t $(IMAGE_NAME) \
		-f $(CONTAINER_FILE) \
		.

	sed -i 's|AllowedIPs = 10.8.0.0/24|AllowedIPs = GH_SEC_WG_ALLOWEDIPS|' ./files/system/etc/wireguard/wg0.conf
	sed -i 's|PublicKey = /s8cFxU/uc2B9wonFTySaznAjyM5Vtlhs0JY+KnKFww=|PublicKey = GH_SEC_WG_PUBLIC_KEY|' ./files/system/etc/wireguard/wg0.conf
	sed -i 's|Endpoint = wg.placeholder.com:51820|Endpoint = GH_SEC_WG_ENDPOINT|' ./files/system/etc/wireguard/wg0.conf
	sed -i 's|rdp.placeholder.com|GH_SEC_RDP_ENDPOINT|' ./files/system/etc/skel/.config/autostart/org.kde.krdc.desktop
	sed -i 's|rdp.placeholder.com|GH_SEC_RDP_ENDPOINT|' ./files/system/etc/skel/.config/krdcrc

bib_image:
	$(SUDO) rm -rf ./output
	mkdir -p ./output

	cp $(IMAGE_CONFIG) ./output/config.toml
	# Don't bother trying to switch to a new image, this is just for local testing
	sed -i '/bootc switch/d' ./output/config.toml

	if [ "$(IMAGE_TYPE)" = "iso" ]; then
		LIBREPO=False;
	else
		LIBREPO=True;
	fi;

	$(PODMAN) run \
		--rm \
		-it \
		--privileged \
		--pull=newer \
		--security-opt label=type:unconfined_t \
		-v ./output:/output \
		-v ./output/config.toml:/config.toml:ro \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		quay.io/centos-bootc/bootc-image-builder:latest \
		--type $(IMAGE_TYPE) \
		--use-librepo=$$LIBREPO \
		--progress verbose \
		$(IMAGE_NAME)

iso:
	make bib_image IMAGE_TYPE=iso

qcow2:
	make bib_image IMAGE_TYPE=qcow2

run-qemu-qcow:
	qemu-system-x86_64 \
		-M accel=kvm \
		-cpu host \
		-smp 2 \
		-m 4096 \
		-bios /usr/share/OVMF/x64/OVMF.4m.fd \
		-serial stdio \
		-snapshot $(QEMU_DISK_QCOW2)

run-qemu-iso:
	mkdir -p ./output
	# Make a disk to install to
	[[ ! -e $(QEMU_DISK_RAW) ]] && dd if=/dev/null of=$(QEMU_DISK_RAW) bs=1M seek=20480

	qemu-system-x86_64 \
		-M accel=kvm \
		-cpu host \
		-smp 2 \
		-m 4096 \
		-bios /usr/share/OVMF/x64/OVMF.4m.fd \
		-serial stdio \
		-boot d \
		-cdrom $(QEMU_ISO) \
		-hda $(QEMU_DISK_RAW)

run-qemu:
	qemu-system-x86_64 \
		-M accel=kvm \
		-cpu host \
		-smp 2 \
		-m 4096 \
		-bios /usr/share/OVMF/x64/OVMF.4m.fd \
		-serial stdio \
		-hda $(QEMU_DISK_RAW)

vm:
	cp -f output/bootiso/install.iso $(LIBVIRT_ISO)
	if virsh dominfo $(LIBVIRT_DOMAIN); then
		[[ $$(virsh domstate $(LIBVIRT_DOMAIN)) == "running" ]] && virsh destroy $(LIBVIRT_DOMAIN)
		virsh undefine $(LIBVIRT_DOMAIN) --nvram
	fi
	[[ -f $(LIBVIRT_QCOW2) ]] || qemu-img create -f qcow2 $(LIBVIRT_QCOW2) 64G
	virt-install \
		--hvm \
		--noautoconsole \
		--osinfo almalinux10 \
		-n $(LIBVIRT_DOMAIN) \
		--memory 2048 \
		--vcpus 2 \
		--cdrom $(LIBVIRT_ISO) \
		--disk $(LIBVIRT_QCOW2) \
		--network network=LAN10 \
		--graphics spice \
		--wait

vm-tpm:
	cp -f output/bootiso/install.iso $(LIBVIRT_ISO)
	if virsh dominfo $(LIBVIRT_DOMAIN); then
		[[ $$(virsh domstate $(LIBVIRT_DOMAIN)) == "running" ]] && virsh destroy $(LIBVIRT_DOMAIN)
		virsh undefine $(LIBVIRT_DOMAIN) --nvram
	fi
	[[ -f $(LIBVIRT_QCOW2) ]] || qemu-img create -f qcow2 $(LIBVIRT_QCOW2) 64G
	virt-install \
		--hvm \
		--noautoconsole \
		--osinfo almalinux10 \
		-n $(LIBVIRT_DOMAIN) \
		--boot uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=yes,firmware.feature1.name=enrolled-keys,firmware.feature1.enabled=no \
		--tpm default \
		--memory 2048 \
		--vcpus 2 \
		--cdrom $(LIBVIRT_ISO) \
		--disk $(LIBVIRT_QCOW2) \
		--network network=LAN10 \
		--graphics spice \
		--wait

vm-tpm-sb:
	cp -f output/bootiso/install.iso $(LIBVIRT_ISO)
	if virsh dominfo $(LIBVIRT_DOMAIN); then
		[[ $$(virsh domstate $(LIBVIRT_DOMAIN)) == "running" ]] && virsh destroy $(LIBVIRT_DOMAIN)
		virsh undefine $(LIBVIRT_DOMAIN) --nvram
	fi
	[[ -f $(LIBVIRT_QCOW2) ]] || qemu-img create -f qcow2 $(LIBVIRT_QCOW2) 64G
	virt-install \
		--hvm \
		--noautoconsole \
		--osinfo almalinux10 \
		-n $(LIBVIRT_DOMAIN) \
		--boot uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=yes,firmware.feature1.name=enrolled-keys,firmware.feature1.enabled=yes \
		--tpm default \
		--memory 2048 \
		--vcpus 2 \
		--cdrom $(LIBVIRT_ISO) \
		--disk $(LIBVIRT_QCOW2) \
		--network network=LAN10 \
		--graphics spice \
		--wait



