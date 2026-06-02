# Jetson TX1 Ubuntu 20.04 Upgrade for PX4 / QGroundControl Development

This repository documents a non-official upgrade path for the NVIDIA Jetson TX1:

- keep the original Jetson Linux / L4T R32.7.x kernel, bootloader, device tree and BSP packages;
- hold all `nvidia-l4t-*` packages;
- upgrade the Ubuntu userland from 18.04 to 20.04;
- use the upgraded TX1 as an ARM64 development terminal and PX4 / QGroundControl field debugging station.

The tested target state:

```text
Ubuntu: 20.04.6 LTS
Kernel: 4.9.337-tegra
L4T: R32.7.6
Architecture: aarch64
Display manager: gdm3
Rootfs: SD card
GPIO: available through /dev/gpiochip*
Docker: available
```

## Why

Jetson TX1 officially belongs to the JetPack 4 / Jetson Linux R32 era, which is based on Ubuntu 18.04. For PX4 and QGroundControl development, Ubuntu 18.04 is increasingly inconvenient for modern build tools, Qt/QML dependencies, Docker workflows, Node.js, Python and general CLI tooling.

This upgrade path does not try to replace the Jetson BSP with a mainline kernel. Instead, it keeps the TX1-specific L4T stack and only upgrades the userland to Ubuntu 20.04. That makes the board more useful as a practical field debugging terminal while retaining display, GPIO, I2C and low-level hardware compatibility.

## Main Documents

- [Upgrade Procedure](docs/JETSON_TX1_UBUNTU20_UPGRADE.md)
- [PX4 / QGroundControl Value](docs/JETSON_TX1_QGC_PX4_VALUE.md)

## Scripts

Scripts are in [scripts/](scripts). They are organized by phase:

```text
00_*  preflight and sudo checks
10_*  pre-upgrade backup and apt preparation
20_*  release upgrade
30_*  post-upgrade repair
40_*  service, AppStream and apt mirror cleanup
50_*  post-reboot and system verification
60_*  GPIO and development tools
70_*  Chinese input method
```

Read the documents before running scripts. This is not a one-click official installer.

## Safety

This path is not officially supported by NVIDIA. Use it only if you can recover the TX1 from a backup or SD card image.

Recommended:

- use an SD card rootfs rather than your only eMMC system;
- keep a full image backup;
- keep `nvidia-l4t-*` packages held;
- do not casually restore NVIDIA bionic-era apt repositories after upgrading to focal;
- do not use this if your project depends on full CUDA / TensorRT / DeepStream compatibility.

## Minimal Flow

```bash
# Hold Jetson BSP packages.
sudo apt-mark hold $(dpkg-query -W -f='${binary:Package}\n' 'nvidia-l4t-*')

# Clean current 18.04 state.
sudo apt-get update
sudo dpkg --configure -a
sudo apt-get -f install
sudo apt-get dist-upgrade
sudo apt-get autoremove --purge

# Upgrade.
sudo apt-get install -y update-manager-core ubuntu-release-upgrader-core
sudo do-release-upgrade

# Repair and verify after upgrade.
sudo dpkg --configure -a
sudo apt-get -f install
sudo apt-get dist-upgrade
sudo apt-get autoremove --purge
sudo reboot
```

After reboot:

```bash
cat /etc/os-release
uname -a
cat /etc/nv_tegra_release
systemctl is-system-running
systemctl --failed --no-pager
apt-mark showhold | grep -c '^nvidia-l4t-'
sudo dpkg --audit
sudo apt-get -s -f install
```

## Tested Use Case

The upgraded TX1 was used to deploy and rebuild QGroundControl for PX4 flight controller debugging.

This makes the TX1 a compact ARM64 ground-control and field debugging station:

```text
TX1 + custom QGroundControl
        |
        | USB / serial / UDP / telemetry radio
        |
PX4 flight controller
```

## References

- NVIDIA Jetson Linux R32.7.6: <https://developer.nvidia.com/embedded/linux-tegra-r3276>
- NVIDIA Jetson Linux Archive: <https://developer.nvidia.com/embedded/jetson-linux-archive>
- QGroundControl Developer Guide: <https://docs.qgroundcontrol.com/Stable_V5.0/en/qgc-dev-guide/index.html>
- PX4 Documentation: <https://docs.px4.io/>

