# ba0fde3d-bee7-4307-b97b-17d0d20aff50
SUDO = sudo
PODMAN = $(SUDO) podman

IMAGE_NAME ?= localhost/bootc-images/alma
ISO_IMAGE ?= quay.io/almalinuxorg/almalinux-bootc:9
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

	# Local dev: add bogus wireguard pubkey + disable firewalld + add own public key
	sed -i 's|PublicKey = GH_SEC_WG_PUBLIC_KEY|PublicKey = /s8cFxU/uc2B9wonFTySaznAjyM5Vtlhs0JY+KnKFww=|' ./files/system/etc/wireguard/wg0.conf
	echo 'systemctl disable firewalld.service' >> files/scripts/12-firewall.sh
	mkdir -p ./files/system/usr/ssh
	cat ~/.ssh/id_ed25519.pub > ./files/system/usr/ssh/authorized_keys

	$(PODMAN) build \
		--security-opt=label=disable \
		--cap-add=all \
		--device /dev/fuse \
		--secret id=mok_key,src=/etc/pki/dkms/bootc-alma/mok.key \
		--build-arg IMAGE_NAME=$(IMAGE_NAME) \
		--build-arg IMAGE_REGISTRY=localhost \
		--build-arg VARIANT=$(VARIANT) \
		-t $(IMAGE_NAME) \
		-f $(CONTAINER_FILE) \
		.

	sed -i 's|PublicKey = /s8cFxU/uc2B9wonFTySaznAjyM5Vtlhs0JY+KnKFww=|PublicKey = GH_SEC_WG_PUBLIC_KEY|' ./files/system/etc/wireguard/wg0.conf
	sed -i '/systemctl disable firewalld.service/d' ./files/scripts/12-firewall.sh
	rm -rf ./files/system/usr/ssh

bib_image:
	$(SUDO) rm -rf ./output
	mkdir -p ./output

	cp $(IMAGE_CONFIG) ./output/config.toml
	sed -i 's#<UPDATE_IMAGE_REF>#ghcr.io/beokko/assfisc-thin-client:latest#g' ./output/config.toml

	if [ "$(IMAGE_TYPE)" = "iso" ]; then
		LIBREPO=False;
	else
		LIBREPO=True;
	fi;

	$(PODMAN) pull $(ISO_IMAGE)

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
		$(ISO_IMAGE)

iso:
	make bib_image IMAGE_TYPE=iso

qcow2:
	make bib_image IMAGE_TYPE=qcow2

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
		--cpu IvyBridge-v2 \
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
		--cpu IvyBridge-v2 \
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
		--cpu IvyBridge-v2 \
		--vcpus 2 \
		--cdrom $(LIBVIRT_ISO) \
		--disk $(LIBVIRT_QCOW2) \
		--network network=LAN10 \
		--graphics spice \
		--wait



