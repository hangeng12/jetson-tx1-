# Disclaimer

This is not an official NVIDIA-supported upgrade path.

This repository documents a tested but non-official method for upgrading the Ubuntu userland on a Jetson TX1 from Ubuntu 18.04 to Ubuntu 20.04 while keeping the original Jetson Linux / L4T R32.7.x kernel, bootloader, device tree and BSP packages.

Use this at your own risk.

Before attempting the upgrade:

- create a full SD card or rootfs backup;
- make sure you can recover the device through SD card restore, serial console, HDMI console or flashing tools;
- keep all `nvidia-l4t-*` packages held;
- do not blindly restore NVIDIA bionic-era apt repositories after upgrading to focal;
- do not use this workflow if your project requires full official JetPack / CUDA / TensorRT / DeepStream compatibility.

The author is not responsible for data loss, boot failure, hardware damage, broken packages or any other issue caused by following this guide.

## 中文说明

本项目不是 NVIDIA 官方支持的升级路径。

本文记录的是在 Jetson TX1 上保留 L4T R32.7.x 内核、bootloader、设备树和 BSP 包，同时将 Ubuntu 用户态从 18.04 升级到 20.04 的实测流程。

请自行承担风险。执行前务必做好完整 SD 卡或 rootfs 备份，并确认可以通过 SD 卡恢复、串口、HDMI 或刷机工具恢复设备。
