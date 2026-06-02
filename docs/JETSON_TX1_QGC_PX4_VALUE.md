# 将 Jetson TX1 升级为 PX4 / QGroundControl 现场调试地面站的方案价值

## 1. 项目定位

本方案的目标不是把 Jetson TX1 改造成一台“最新 Jetson”，也不是追求完整 CUDA / TensorRT / DeepStream / JetPack AI 生态兼容。

本方案的实际定位是：

> 将一台旧款 Jetson TX1 改造成可携带、可编译、可运行 QGroundControl、可连接 PX4 飞控、可做 MAVLink / 串口 / GPIO / I2C 调试的 ARM64 嵌入式地面站终端。

升级后的 TX1 可以承担以下角色：

- QGroundControl 源码编译机
- QGroundControl 运行终端
- PX4 参数调试地面站
- MAVLink telemetry 监视器
- 飞控固件刷写和验证工具
- 串口 / USB / 网络 / GPIO / I2C 外设调试平台
- 现场便携式 Linux 开发终端

简而言之，这个项目的核心价值是：

> Reviving Jetson TX1 as a modern PX4 / QGroundControl field debugging terminal.

## 2. 技术背景

Jetson TX1 官方 Jetson Linux / L4T R32.x 系列基于 Ubuntu 18.04。NVIDIA 官方 Jetson Linux R32.7.6 页面说明，L4T 是 Jetson 的 BSP，包含 Linux kernel 4.9、bootloader、NVIDIA drivers、flashing utilities，并且 sample filesystem 基于 Ubuntu 18.04。

同时，R32.7.6 / JetPack 4.6.6 是 Jetson Linux R32 / JetPack 4 的最终版本之一。对于 TX1 这类旧平台，官方支持基本停留在 Ubuntu 18.04 时代。

Ubuntu 18.04 对现代开发环境已经逐渐不友好，尤其是在以下方面：

- 新版本 Qt / QML / CMake / Ninja / GCC / Python 工具链
- Docker 和容器化构建环境
- 新版 QGroundControl 源码构建
- Node.js / CLI 开发工具
- 新版依赖库和软件包维护
- 现代中文输入法、桌面环境和开发体验

因此，本方案采用折中路线：

- 保留 Jetson TX1 的 L4T R32.7.x kernel、bootloader、BSP 和设备树。
- 锁定 `nvidia-l4t-*` 包，避免升级破坏 TX1 的底层硬件支持。
- 将 Ubuntu userland 从 18.04 升级到 20.04。
- 将设备定位为通用 ARM64 开发终端和 PX4/QGC 调试地面站。

## 3. 核心方案

本方案的核心不是“强刷新系统”，而是“保留底层，升级用户态”。

升级后的系统形态：

```text
Ubuntu userland: 20.04.6 LTS
Kernel:          4.9.337-tegra
L4T:             R32.7.6
Bootloader:      L4T R32.7.x retained
BSP packages:    nvidia-l4t-* held
Rootfs:          SD card
Architecture:    aarch64
Desktop:         GNOME / gdm3
```

关键处理：

```bash
sudo apt-mark hold $(dpkg-query -W -f='${binary:Package}\n' 'nvidia-l4t-*')
```

实测最终状态：

```text
OS: Ubuntu 20.04.6 LTS
Kernel: Linux 4.9.337-tegra
L4T: R32.7.6
systemctl is-system-running: running
failed units: 0
held nvidia-l4t packages: 26
GPIO: /dev/gpiochip0..3 available
Docker: active
GUI: gdm3 active
```

这意味着 TX1 的系统用户态已经更新到 Ubuntu 20.04，但启动链路、内核、GPIO、显示和板级支持仍保持 NVIDIA L4T。

## 4. 为什么这个方案适合 QGroundControl / PX4 调试

### 4.1 QGroundControl 本身适合源码定制

QGroundControl 官方开发文档明确提供源码获取和构建流程。QGC 是跨平台项目，使用 Qt / QML 构建 UI，支持 Linux、Windows、macOS、Android 等平台。

对于 PX4 调试场景，重新编译 QGC 的价值很高，因为可以修改：

- 地面站 UI
- MAVLink 消息显示
- 飞控参数面板
- 自定义飞控状态页
- 串口 / UDP / telemetry 连接逻辑
- 自定义 PX4 参数解释
- 自定义 MAVLink dialect / message 支持
- 日志下载、遥测显示、调试工具入口

直接在 TX1 上重新编译和运行 QGC，可以把“开发环境”和“目标运行环境”合并到同一台 ARM64 设备上。

### 4.2 PX4 与 QGC 的调试关系天然紧密

PX4 官方文档中，QGroundControl 用于：

- 刷写 PX4 固件
- 配置飞控
- 修改参数
- 查看实时飞行信息
- 规划和执行任务
- 进行标准配置和校准

PX4 使用 MAVLink 与 QGroundControl 等地面站通信。对于飞控调试来说，QGC 不只是一个 UI 工具，而是连接 PX4、MAVLink、参数系统、固件刷写和 telemetry 链路的核心入口。

因此，把 QGC 部署到 TX1 上后，TX1 可以形成完整的现场调试闭环：

```text
TX1 + custom QGC
        |
        | USB / Serial / UDP / Wi-Fi telemetry / radio telemetry
        |
PX4 flight controller
```

### 4.3 ARM64 原生验证更接近最终部署环境

很多问题在 x86 开发机上不容易暴露，但在 ARM64 目标设备上会出现，例如：

- Qt 插件路径问题
- QML 模块缺失
- OpenGL / EGL / 显示后端问题
- 字体显示问题
- 中文输入法问题
- USB 串口权限问题
- MAVLink 连接稳定性问题
- AppImage 与 native binary 差异
- ARM64 架构下的依赖兼容问题

如果开发流程是：

```text
x86 PC 编译 -> 拷贝到 TX1 -> 运行测试 -> 出错 -> 回 PC 修改
```

调试链路会比较长。

升级后的 TX1 可以直接变成：

```text
TX1 修改源码 -> TX1 编译 -> TX1 运行 QGC -> TX1 连接 PX4 飞控验证
```

这对 QGC/PX4 这种依赖真实硬件、真实串口、真实遥测链路的软件尤其有价值。

## 5. 相比保留 Ubuntu 18.04 的优势

### 5.1 更现代的软件生态

Ubuntu 20.04 相比 18.04 更适合安装和维护现代开发工具：

```text
git
cmake
ninja
Docker
Python3
Node.js
Qt/QML build dependencies
MAVLink/PX4 helper tools
ripgrep
tmux
gpiod
i2c-tools
```

对 QGroundControl 源码构建来说，这比 Ubuntu 18.04 更容易处理依赖。

### 5.2 更适合作为开发终端长期使用

Ubuntu 18.04 的桌面、输入法、软件源和开发工具都逐渐老化。升级到 20.04 后，可以获得更好的：

- GNOME 桌面体验
- 中文语言包和中文输入法
- Docker 支持
- Python3 支持
- Node.js / CLI 工具支持
- apt 软件源可维护性

这让 TX1 更适合做“手持智能开发终端”，而不仅仅是一块旧开发板。

### 5.3 不破坏 TX1 关键底层驱动

如果直接刷非官方 Ubuntu 22.04 / 24.04 rootfs 或主线 kernel，可能会遇到：

- 启动链路不稳定
- 显示驱动问题
- GPIO / I2C / 设备树问题
- NVIDIA BSP 丢失
- 图形界面不可用
- 调试成本过高

本方案保留 L4T kernel / bootloader / BSP，避免把风险集中到底层硬件支持上。

对于 QGC/PX4 地面站来说，最重要的是：

```text
图形界面稳定
USB/串口稳定
网络稳定
GPIO/I2C 可用
QGC 能编译和运行
PX4 飞控能连接和调试
```

而不是追求最新 kernel。

## 6. 相比直接升级到 Ubuntu 22.04 / 24.04 的优势

Jetson TX1 是旧平台，直接追求高版本 Ubuntu 往往会带来更大风险。

本方案选择 Ubuntu 20.04 的原因是：

- 比 Ubuntu 18.04 新很多，足以改善开发工具链。
- 比 Ubuntu 22.04 / 24.04 更保守，依赖跨度较小。
- 更容易与 L4T R32.x 的旧 kernel 和用户态驱动共存。
- 对 QGC/PX4 调试用途已经足够。
- 便于保持桌面、GPIO、网络、Docker 等关键功能可用。

对于“工程可用性”而言，Ubuntu 20.04 是一个合理折中点。

## 7. 对 PX4 飞控调试的实际价值

升级后的 TX1 可以在现场承担以下任务。

### 7.1 QGroundControl 功能验证

- 运行原版或自定义 QGC
- 验证 UI 修改
- 验证参数页面修改
- 验证 MAVLink 消息解析
- 验证遥测链路稳定性
- 验证串口 / UDP / TCP 连接逻辑

### 7.2 PX4 参数调试

- 读取和修改 PX4 参数
- 验证参数显示逻辑
- 对比不同固件版本的参数变化
- 调试自定义参数分组

### 7.3 PX4 固件刷写和基础配置

- 连接飞控
- 刷写 PX4 固件
- 做 airframe、传感器、遥控、飞行模式、安全、电机等配置检查
- 验证 QGC 与飞控固件之间的兼容性

### 7.4 MAVLink 调试

- 查看 MAVLink telemetry
- 调试自定义 MAVLink 消息
- 检查消息频率
- 检查串口带宽和丢包
- 调试 MAVLink console / inspector

### 7.5 外设调试

TX1 不只是地面站电脑，也可以直接接外设：

```text
USB telemetry radio
USB-to-UART
GPIO button
status LED
buzzer
I2C display
network telemetry bridge
```

这使它适合做一个集成式现场调试平台。

## 8. 对 QGC 自定义编译的价值

你已经在 TX1 上重新编译了 QGC，这正是该方案最有说服力的使用场景之一。

它证明 TX1 不是单纯“能运行 Ubuntu 20.04”，而是能参与完整工程流程：

```text
拉取 QGC 源码
安装构建依赖
编译 QGC
运行 QGC
连接 PX4 飞控
验证地面站行为
现场调试问题
```

对 GitHub 项目来说，这比“系统升级教程”更有价值。项目叙事可以从：

> How to upgrade Jetson TX1 to Ubuntu 20.04

提升为：

> How to revive Jetson TX1 as an ARM64 PX4 / QGroundControl field debugging station

这样更能体现工程意义。

## 9. Docker 的价值

升级后 Docker 可用，这对 QGC/PX4 调试有两个价值：

1. 可以隔离构建依赖，避免污染 host 系统。
2. 可以复现实验环境，减少“这次能编译，下次不能编译”的问题。

建议使用方式：

- Host 系统负责图形界面、USB、串口、GPIO、网络和实际运行。
- Docker 用于构建、依赖隔离、工具链管理。

对于 TX1 这种内存有限的老设备，Docker 也可以帮助控制环境复杂度。

## 10. 方案优势总结

本方案的优势可以总结为：

1. **延长 TX1 生命周期**  
   让停留在 Ubuntu 18.04 时代的 TX1 重新进入可维护开发环境。

2. **保留 L4T 底层硬件支持**  
   不替换 kernel / bootloader / BSP，继续保留 TX1 的显示、GPIO、I2C、设备树和启动链路。

3. **适合 QGroundControl 源码构建**  
   Ubuntu 20.04 更适合安装现代构建工具链和依赖。

4. **适合 PX4 飞控现场调试**  
   可直接连接飞控，进行固件、参数、telemetry、MAVLink 和任务调试。

5. **缩短调试闭环**  
   在同一台 ARM64 设备上完成修改、编译、运行、连接飞控和验证。

6. **支持 Docker 和现代 CLI 工具**  
   便于构建隔离、工具链管理和远程开发。

7. **GPIO / I2C / 串口能力保留**  
   适合扩展状态灯、按键、遥测模块、小屏等现场调试外设。

8. **比直接刷高版本系统更稳妥**  
   Ubuntu 20.04 是工程可用性和底层兼容性之间的折中点。

## 11. 局限性

这个方案也需要诚实说明限制：

- 不是 NVIDIA 官方支持的升级路径。
- 不保证 CUDA / TensorRT / DeepStream / VisionWorks 完整兼容。
- 不建议解除 `nvidia-l4t-*` 包 hold。
- 不建议在 focal userland 上随意恢复 NVIDIA bionic-era apt repo。
- TX1 性能和内存有限，QGC 编译速度不会快。
- 编译大型项目时建议开启 swap / zram。
- 对 QGC 新版本的 Qt 依赖需要单独处理。
- 如果目标是 AI 加速推理平台，应优先考虑更新的 Jetson 硬件。

## 12. README 可用摘要

下面这段可以直接放进 GitHub README：

```text
This project revives the NVIDIA Jetson TX1 as a practical ARM64 field debugging terminal for PX4 and QGroundControl development.

Instead of replacing the Jetson BSP with an unsupported mainline kernel, the upgrade keeps the original L4T R32.7.x kernel, bootloader, device tree and NVIDIA board-support packages, while upgrading the Ubuntu userland from 18.04 to 20.04. This preserves the low-level hardware compatibility of the TX1, including display, GPIO, I2C and board-specific drivers, while making the system much more usable for modern development workflows.

The upgraded TX1 can build and run a customized QGroundControl, connect directly to PX4 flight controllers over USB, serial, UDP or telemetry radio, inspect MAVLink traffic, tune parameters, validate firmware behavior and serve as a compact field ground-control station.
```

中文版本：

```text
本项目将 NVIDIA Jetson TX1 重新利用为一台面向 PX4 / QGroundControl 的 ARM64 现场调试地面站。

方案没有替换 TX1 的 L4T 内核、bootloader、设备树和 NVIDIA BSP，而是在保留底层硬件兼容性的基础上，将 Ubuntu 用户态从 18.04 升级到 20.04。这样既保留了 TX1 的显示、GPIO、I2C、串口、网络和板级支持，又获得了更适合现代开发的 Ubuntu 20.04 软件生态。

升级后的 TX1 可以直接编译和运行自定义 QGroundControl，连接 PX4 飞控，进行 MAVLink telemetry 查看、参数调试、固件验证、串口/UDP 链路测试和现场飞控调试。
```

## 13. 适合的项目标题

可选标题：

- `Reviving Jetson TX1 as a PX4/QGroundControl Field Debugging Station`
- `Jetson TX1 Ubuntu 20.04 Upgrade for PX4 and QGroundControl Development`
- `Jetson TX1 as an ARM64 Ground Control Terminal for PX4`
- `Ubuntu 20.04 Userland Upgrade on Jetson TX1 for QGC/PX4 Debugging`

中文标题：

- `将 Jetson TX1 改造为 PX4/QGroundControl 现场调试地面站`
- `Jetson TX1 升级 Ubuntu 20.04 并部署 QGC/PX4 调试环境`
- `基于 Jetson TX1 的 ARM64 便携式无人机地面站终端`

## 14. 参考资料

- NVIDIA Jetson Linux R32.7.6  
  <https://developer.nvidia.com/embedded/linux-tegra-r3276>

- QGroundControl Developer Guide  
  <https://docs.qgroundcontrol.com/Stable_V5.0/en/qgc-dev-guide/index.html>

- QGroundControl source build guide  
  <https://docs.qgroundcontrol.com/master/en/qgc-dev-guide/getting_started/index.html>

- QGroundControl guide  
  <https://docs.qgroundcontrol.com/>

- PX4 basic concepts: QGroundControl and PX4  
  <https://docs.px4.io/v1.14/en/getting_started/px4_basic_concepts.html>

- PX4 standard configuration with QGroundControl  
  <https://docs.px4.io/v1.13/en/config/>

- PX4 MAVLink messaging  
  <https://docs.px4.io/main/en/mavlink/>

