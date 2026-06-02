# jetson-tx1-
本项目将 NVIDIA Jetson TX1 重新利用为一台面向 PX4 / QGroundControl 的 ARM64 现场调试地面站。  方案没有替换 TX1 的 L4T 内核、bootloader、设备树和 NVIDIA BSP，而是在保留底层硬件兼容性的基础上，将 Ubuntu 用户态从 18.04 升级到 20.04。这样既保留了 TX1 的显示、GPIO、I2C、串口、网络和板级支持，又获得了更适合现代开发的 Ubuntu 20.04 软件生态。  升级后的 TX1 可以直接编译和运行自定义 QGroundControl，连接 PX4 飞控，进行 MAVLink telemetry 查看、参数调试、固件验证、串口/UDP 链路测试和现场飞控调试。
