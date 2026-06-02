# Jetson TX1 Ubuntu 20.04 Upgrade for PX4 / QGroundControl Development

This repository documents a non-official upgrade path for the NVIDIA Jetson TX1:

- keep the original Jetson Linux / L4T R32.7.x kernel, bootloader, device tree and BSP packages;
- hold all `nvidia-l4t-*` packages;
- upgrade the Ubuntu userland from 18.04 to 20.04;
- use the upgraded TX1 as an ARM64 development terminal and PX4 / QGroundControl field debugging station.

## 中文简介

本项目记录了将 NVIDIA Jetson TX1 保留 L4T R32.7.x 内核、bootloader、设备树和 BSP 包，同时将 Ubuntu 用户态从 18.04 升级到 20.04 的实测流程。

升级后的 TX1 可作为 ARM64 便携式开发终端和 PX4 / QGroundControl 现场调试地面站，用于 QGroundControl 源码编译、PX4 飞控连接、MAVLink telemetry 查看、参数调试、固件验证、GPIO / I2C / 串口外设调试等场景。

## Tested Hardware

| Item | Value |
|---|---|
| Board | NVIDIA Jetson TX1 |
| Jetson Linux / L4T | R32.7.6 |
| Kernel | 4.9.337-tegra |
| Before upgrade | Ubuntu 18.04.6 LTS |
| After upgrade | Ubuntu 20.04.6 LTS |
| Architecture | aarch64 |
| Root filesystem | SD card |
| Display manager | gdm3 |
| Desktop | GNOME |
| GPIO | `/dev/gpiochip0` to `/dev/gpiochip3` |
| Main use case | PX4 / QGroundControl field debugging |

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
- [Disclaimer](DISCLAIMER.md)

## Screenshots

Screenshots can be added under [assets/](assets) after validating QGroundControl on the target TX1.

Recommended screenshots:

- QGroundControl running on Jetson TX1
- QGroundControl connected to a PX4 flight controller
- terminal output showing `os-release`, `uname`, and `nv_tegra_release`
- `gpiodetect` output showing available GPIO chips

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

## Script Overview

| Script | Purpose |
|---|---|
| `00_sudo_test.sh` | Check sudo access |
| `10_preflight_backup_and_hold_l4t.sh` | Back up system metadata and hold L4T packages |
| `11_prepare_apt_18_04.sh` | Clean the current Ubuntu 18.04 apt/dpkg state |
| `20_run_release_upgrade.sh` | Start the interactive release upgrade |
| `30_postupgrade_repair.sh` | Repair apt/dpkg after upgrade |
| `31_repair_appstream.sh` | Repair AppStream cache and apt hook issues |
| `40_finalize_services_and_apt.sh` | Clean failed services and verify status |
| `41_switch_apt_mirror_https.sh` | Switch to an HTTPS ubuntu-ports mirror |
| `50_post_reboot_verify.sh` | Verify system after reboot |
| `60_dev_gpio_prep.sh` | Install development and GPIO tools |
| `70_install_chinese_ime.sh` | Install Chinese IBus input method |

## Safety

This path is not officially supported by NVIDIA. Use it only if you can recover the TX1 from a backup or SD card image.

Recommended:

- use an SD card rootfs rather than your only eMMC system;
- keep a full image backup;
- keep `nvidia-l4t-*` packages held;
- do not casually restore NVIDIA bionic-era apt repositories after upgrading to focal;
- do not use this if your project depends on full CUDA / TensorRT / DeepStream compatibility.

## Known Issues

- This is not an official NVIDIA-supported upgrade path.
- `nvidia-l4t-*` packages must remain held.
- NVIDIA bionic-era Jetson apt repositories should not be blindly restored after upgrading to focal.
- Chromium packages may conflict during release upgrade and may need to be removed.
- AppStream apt hooks may need repair after upgrade.
- Some `ubuntu-ports` mirrors may require HTTPS and IPv4 forcing.
- QGroundControl builds on TX1 are slow due to limited CPU and memory.
- CUDA, TensorRT, DeepStream and full JetPack compatibility are not guaranteed.

## Recovery

Before attempting the upgrade, create a full SD card image from another Linux machine:

```bash
sudo dd if=/dev/sdX of=jetson-tx1-before-focal.img bs=4M status=progress conv=fsync
```

Restore if needed:

```bash
sudo dd if=jetson-tx1-before-focal.img of=/dev/sdX bs=4M status=progress conv=fsync
```

Replace `/dev/sdX` with the actual SD card device. Be careful: using the wrong device path can destroy data.

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

Typical field debugging workflow:

```text
Jetson TX1
  -> build custom QGroundControl
  -> run QGC on ARM64
  -> connect PX4 flight controller through USB / serial / UDP / telemetry radio
  -> inspect MAVLink telemetry
  -> tune PX4 parameters
  -> validate ground-station behavior
```

## References

- NVIDIA Jetson Linux R32.7.6: <https://developer.nvidia.com/embedded/linux-tegra-r3276>
- NVIDIA Jetson Linux Archive: <https://developer.nvidia.com/embedded/jetson-linux-archive>
- QGroundControl Developer Guide: <https://docs.qgroundcontrol.com/Stable_V5.0/en/qgc-dev-guide/index.html>
- PX4 Documentation: <https://docs.px4.io/>

