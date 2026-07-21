# bootc-alma thin client

An [AlmaLinux 10](https://almalinux.org/) [bootc](https://containers.github.io/bootc/)-based OS image for RDP thin clients. Built as an OCI container image and deployed atomically; updates are pulled and applied like any other container image.

## What it does

- KDE Plasma desktop that auto-connects to a configured RDP server on login
- WireGuard VPN, brought up automatically and reconfigurable from a central endpoint without re-provisioning
- LUKS2 disk encryption with interactive first-boot setup (recovery key, optional TPM2 unlock)
- Ephemeral desktop user, recreated on every boot; only a few dotfiles persist
- Locked-down firewall, hardened SSH, minimal service set
- Printing, smartcard, and Bluetooth support for office peripherals
- RustDesk bundled (disabled by default) for out-of-band remote support
- Belgian French locale/keyboard throughout, including at the LUKS prompt
- Unattended, signed bootc updates

See `files/scripts/` and `files/system/` for the concrete build steps and shipped config.

## Repository structure

```
files/
  scripts/   # Build-time provisioning scripts, run in order during the image build
  system/    # Files copied verbatim into the image filesystem (units, configs, provisioning scripts)
Dockerfile   # Container image definition
iso.toml     # bootc-image-builder config for producing an installable ISO
env          # Runtime config baked into the image (endpoints, prefix)
Taskfile.yml # Local build/test targets (see below)
```

## CI/CD

CI runs as reusable workflows from a companion `atomic-ci` repo. On push/PR, the image is built, SBOM'd, smoke-tested, and — on `main` — signed, retagged, and released. A separate manual workflow builds an installable ISO. Repository variables/secrets provide the RDP/WireGuard/signing keys the build needs.

## Local development

Local builds and VM testing are driven by [Task](https://taskfile.dev/). Edit the vars at the top of `Taskfile.yml` to match your test environment.

```sh
task            # List available tasks
task image       # Build the container image locally (requires sudo + podman)
task iso         # Build a bootable ISO via bootc-image-builder
task qcow2       # Build a QCOW2 disk image
task vm          # Deploy the qcow2 image to a libvirt VM
task vm-tpm      # Same, with a TPM device (Secure Boot setup mode)
task vm-tpm-sb   # Same, with a TPM device and Secure Boot enforced
task clean       # Remove ./output
```
