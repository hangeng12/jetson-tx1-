# Jetson TX1 升级到 Ubuntu 20.04 的非官方流程

> 适用目标：在 Jetson TX1 上保留 L4T R32.7.x 的 kernel、bootloader、BSP、GPIO 支持，把 Ubuntu userland 从 18.04 升级到 20.04。  
> 实测结果：Ubuntu 20.04.6 LTS + Linux `4.9.337-tegra` + L4T R32.7.6 + GNOME 图形界面 + SSH + GPIO + Docker 可用。

## 重要声明

这不是 NVIDIA 官方支持的升级路径。

Jetson TX1 官方 JetPack 4.x / Jetson Linux R32.x 基于 Ubuntu 18.04，R32.7.6 是 Jetson Linux R32 / JetPack 4 的最终版本之一。NVIDIA 官方页面说明 R32.7.6 包含 Linux kernel 4.9、bootloader、NVIDIA drivers、flashing utilities，并且 sample filesystem 基于 Ubuntu 18.04。

参考：

- NVIDIA Jetson Linux R32.7.6: <https://developer.nvidia.com/embedded/linux-tegra-r3276>
- NVIDIA Jetson Linux archive: <https://developer.nvidia.com/embedded/jetson-linux-archive>
- NVIDIA archived Jetson docs: <https://docs.nvidia.com/jetson/archives/index.html>

本文方法的核心思路是：

1. 不升级 Jetson 的 kernel / bootloader / BSP。
2. 锁定 `nvidia-l4t-*` 包，避免 Ubuntu 升级过程替换 TX1 关键组件。
3. 只把 Ubuntu userland 从 bionic 升到 focal。
4. 把 Jetson 当作通用 ARM64 Linux 开发终端使用，而不是追求完整 JetPack/CUDA/TensorRT 官方兼容性。

如果你依赖 CUDA、TensorRT、DeepStream、VisionWorks、官方 JetPack stack，建议不要按本文升级。

## 实测设备状态

升级前：

```text
Board: Jetson TX1
OS: Ubuntu 18.04.6 LTS
Kernel: 4.9.337-tegra
L4T: R32.7.6
Architecture: aarch64
Rootfs: SD card
```

升级后：

```text
OS: Ubuntu 20.04.6 LTS (Focal Fossa)
Kernel: 4.9.337-tegra
L4T: R32.7.6
Rootfs: /dev/mmcblk2p1 mounted on /
Display manager: gdm3
SSH: active
NetworkManager: active
Docker: active
GPIO: /dev/gpiochip0..3 available
```

最终验证摘要：

```text
systemctl is-system-running -> running
systemctl --failed -> 0 failed units
apt list --upgradable -> 0
apt-mark showhold | grep -c '^nvidia-l4t-' -> 26
dpkg --audit -> clean
apt-get -s -f install -> clean
```

## 风险与回滚准备

强烈建议在 SD 卡 rootfs 上做，不要直接拿唯一的 eMMC 系统冒险。

推荐准备：

- 稳定电源。
- SSH 可登录。
- HDMI 或串口调试能力。
- 另一张可启动 SD 卡或 eMMC 原系统。
- 升级前完整镜像备份。

最稳妥的备份是在另一台 Linux 主机上对 SD 卡做镜像：

```bash
sudo dd if=/dev/sdX of=jetson-tx1-before-focal.img bs=4M status=progress conv=fsync
```

注意把 `/dev/sdX` 换成真实 SD 卡设备，千万不要写错。

在 Jetson 上也可以至少保存系统关键信息：

```bash
mkdir -p ~/tx1-upgrade-backup

uname -a | tee ~/tx1-upgrade-backup/uname.txt
cat /etc/os-release | tee ~/tx1-upgrade-backup/os-release.txt
cat /etc/nv_tegra_release | tee ~/tx1-upgrade-backup/nv_tegra_release.txt
findmnt | tee ~/tx1-upgrade-backup/findmnt.txt
df -h | tee ~/tx1-upgrade-backup/df-h.txt
apt-mark showhold | tee ~/tx1-upgrade-backup/apt-holds.txt
dpkg -l 'nvidia-l4t-*' | tee ~/tx1-upgrade-backup/nvidia-l4t-packages.txt
cp -a /etc/apt ~/tx1-upgrade-backup/etc-apt
sudo cp -a /boot ~/tx1-upgrade-backup/boot

tar -czf ~/tx1-upgrade-backup-$(date +%Y%m%d_%H%M%S).tar.gz -C ~ tx1-upgrade-backup
```

## 升级前检查

确认当前系统：

```bash
hostname
whoami
pwd
uname -a
lsb_release -a
cat /etc/nv_tegra_release
findmnt -no SOURCE,TARGET,FSTYPE /
df -h /
free -h
```

确认 rootfs 是 SD 卡时，常见输出类似：

```text
/dev/mmcblk2p1 / ext4
```

如果是 eMMC，常见是：

```text
/dev/mmcblk0p1 / ext4
```

本文实测是在 SD 卡 rootfs 上完成。

## 第一步：锁定 L4T 包

这是整个流程里最重要的一步。

```bash
sudo apt-mark hold $(dpkg-query -W -f='${binary:Package}\n' 'nvidia-l4t-*')
apt-mark showhold | grep '^nvidia-l4t-'
apt-mark showhold | grep -c '^nvidia-l4t-'
```

实测机器最后锁定了 26 个 `nvidia-l4t-*` 包。

典型包包括：

```text
nvidia-l4t-core
nvidia-l4t-kernel
nvidia-l4t-kernel-dtbs
nvidia-l4t-bootloader
nvidia-l4t-x11
nvidia-l4t-firmware
```

不要随便 `apt-mark unhold nvidia-l4t-*`。

## 第二步：整理 18.04 当前系统

```bash
sudo apt-get update
sudo apt-get -f install
sudo dpkg --configure -a
sudo apt-get dist-upgrade
sudo apt-get autoremove --purge
sudo apt-get clean
```

确认没有 broken package：

```bash
sudo dpkg --audit
sudo apt-get -s -f install
```

## 第三步：禁用或避免 Jetson apt 源干扰

Ubuntu release upgrade 会自动禁用第三方源。也可以提前检查：

```bash
ls -l /etc/apt/sources.list.d/
grep -R "repo.download.nvidia.com" /etc/apt/sources.list /etc/apt/sources.list.d || true
```

本文建议：升级到 focal 后不要随便恢复 NVIDIA Jetson apt 源。

原因是 Jetson Linux R32.x 官方 userland 目标是 Ubuntu 18.04。把 focal userland 和 bionic-era Jetson repo 混用，容易造成依赖冲突。

## 第四步：执行 release upgrade

安装升级工具：

```bash
sudo apt-get install -y update-manager-core ubuntu-release-upgrader-core
```

确认 `/etc/update-manager/release-upgrades`：

```bash
grep '^Prompt=' /etc/update-manager/release-upgrades
```

建议为：

```text
Prompt=lts
```

开始升级：

```bash
sudo do-release-upgrade
```

如果通过 SSH 执行，`do-release-upgrade` 通常会提示它将开启一个备用 SSH 端口。按提示继续即可。

过程中常见选择：

- 是否继续升级：继续。
- 第三方源被禁用：接受。
- 配置文件冲突：如果你没有明确要覆盖，一般保留本地版本。
- 是否删除 obsolete packages：谨慎确认后删除。

升级过程中如果断开 SSH，不要立刻断电。先尝试重新 SSH，或通过 HDMI/串口查看。

## 第五步：升级后修复 dpkg/apt

升级完成或半完成后，先收敛 dpkg 状态：

```bash
sudo dpkg --configure -a
sudo apt-get -f install
sudo apt-get dist-upgrade
sudo apt-get autoremove --purge
```

如果遇到 conffile 交互卡住，可以用保留旧配置的方式继续：

```bash
sudo dpkg --force-confold --configure -a
```

如果 apt/dpkg 被旧进程卡住，先确认：

```bash
ps -ef | grep -E 'apt|dpkg|unattended|do-release' | grep -v grep
```

只在确认卡死后再处理进程。不要同时运行多个 apt/dpkg。

## 第六步：处理 AppStream hook 问题

本机升级过程中出现过 AppStream hook 符号错误，表现类似：

```text
appstreamcli: undefined symbol: AS_APPSTREAM_METADATA_PATHS
```

修复方向：

```bash
sudo apt-get install --reinstall appstream
appstreamcli --version
```

如果 `/etc/apt/apt.conf.d/50appstream` 被临时禁用过，升级完成后可以从 dpkg-dist 恢复：

```bash
sudo cp -a /etc/apt/apt.conf.d/50appstream.dpkg-dist /etc/apt/apt.conf.d/50appstream
sudo apt-get update
sudo appstreamcli refresh-cache --force
```

## 第七步：处理 Chromium 相关冲突

Ubuntu 18.04 到 20.04 的升级过程中，`chromium-browser` 和 `chromium-browser-l10n` 可能出现冲突或半配置状态。

如果你不依赖 Chromium，直接移除更省事：

```bash
sudo apt-get remove --purge chromium-browser chromium-browser-l10n
sudo dpkg --configure -a
sudo apt-get -f install
```

## 第八步：修复失败服务

本机升级后 `isc-dhcp-server.service` 曾失败，但它不是桌面终端用途必需服务。

检查失败服务：

```bash
systemctl is-system-running
systemctl --failed --no-pager
```

如果只是未配置的 DHCP server：

```bash
sudo systemctl disable --now isc-dhcp-server.service || true
sudo systemctl disable --now isc-dhcp-server6.service || true
sudo systemctl reset-failed
```

## 第九步：切换可用 apt 镜像

升级后如果 `ports.ubuntu.com` 不稳定，可以切换到国内 `ubuntu-ports` 镜像。

例如清华 HTTPS：

```bash
sudo cp -a /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)
sudo sed -i 's|http://ports.ubuntu.com/ubuntu-ports|https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports|g' /etc/apt/sources.list
sudo sed -i 's|http://mirrors.ustc.edu.cn/ubuntu-ports|https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports|g' /etc/apt/sources.list
```

建议加入 apt 网络配置：

```bash
sudo tee /etc/apt/apt.conf.d/99local-network.conf >/dev/null <<'EOF'
Acquire::ForceIPv4 "true";
Acquire::Retries "3";
Acquire::http::Pipeline-Depth "0";
Acquire::https::Pipeline-Depth "0";
EOF
```

然后：

```bash
sudo apt-get update
```

## 第十步：重启并验证

```bash
sudo reboot
```

重启后检查：

```bash
cat /etc/os-release
uname -a
cat /etc/nv_tegra_release
findmnt -no SOURCE,TARGET,FSTYPE /
df -h /
free -h

systemctl is-system-running
systemctl --failed --no-pager
systemctl is-active ssh
systemctl is-active NetworkManager
systemctl is-active gdm3

apt list --upgradable 2>/dev/null | tail -n +2 | wc -l
apt-mark showhold | grep -c '^nvidia-l4t-'
sudo dpkg --audit
sudo apt-get -s -f install
```

理想输出：

```text
PRETTY_NAME="Ubuntu 20.04.6 LTS"
Linux ... 4.9.337-tegra ... aarch64
systemctl is-system-running -> running
failed units -> 0
held nvidia-l4t packages -> non-zero
upgradable -> 0
```

## GPIO 修复与验证

安装 GPIO 工具：

```bash
sudo apt-get install -y gpiod libgpiod-dev python3-libgpiod i2c-tools
```

添加 GPIO 权限：

```bash
sudo groupadd --system gpio || true
sudo usermod -aG gpio jetson

sudo tee /etc/udev/rules.d/99-gpio-permissions.rules >/dev/null <<'EOF'
KERNEL=="gpiochip*", GROUP="gpio", MODE="0660"
SUBSYSTEM=="gpio", KERNEL=="gpio*", GROUP="gpio", MODE="0660"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=gpio
sudo chgrp gpio /dev/gpiochip* || true
sudo chmod 0660 /dev/gpiochip* || true
```

验证：

```bash
id
ls -l /dev/gpiochip*
gpiodetect
gpioinfo | head -40
```

本机实测：

```text
gpiochip0 [tegra-gpio] (256 lines)
gpiochip1 [tca9539] (16 lines)
gpiochip2 [tca9539] (16 lines)
gpiochip3 [max77620-gpio] (8 lines)
```

## Docker

如果需要 Docker：

```bash
sudo apt-get install -y docker.io
sudo systemctl enable --now docker containerd
sudo usermod -aG docker jetson
```

验证：

```bash
docker --version
systemctl is-active docker
systemctl is-active containerd
```

注意：重新登录后 `docker` 组权限才会生效。

## 中文输入法

GNOME 下推荐 IBus + libpinyin：

```bash
sudo apt-get install -y \
  ibus-libpinyin \
  libpinyin-data \
  language-pack-zh-hans \
  language-pack-gnome-zh-hans \
  fonts-noto-cjk \
  fonts-wqy-microhei \
  fonts-wqy-zenhei

im-config -n ibus
```

把 IBus 环境写入用户 profile：

```bash
cat >> ~/.profile <<'EOF'

# Chinese input method
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
EOF
```

在 GNOME 当前会话中添加输入源：

```bash
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'libpinyin')]"
gsettings set org.gnome.desktop.input-sources mru-sources "[('ibus', 'libpinyin'), ('xkb', 'us')]"
ibus restart
```

如果通过 SSH 配置，需要带上当前桌面会话的 DBus 环境。最简单的方法是配置后注销并重新登录图形桌面。

验证：

```bash
ibus list-engine | grep -Ei 'libpinyin|pinyin|Chinese|中文'
ps -ef | grep ibus
```

应能看到：

```text
libpinyin - Intelligent Pinyin
ibus-engine-libpinyin
```

## 常见问题

### 1. 升级后系统显示 degraded

检查：

```bash
systemctl --failed --no-pager
```

如果是不需要的服务，例如 `isc-dhcp-server`，可以禁用并 reset：

```bash
sudo systemctl disable --now isc-dhcp-server.service || true
sudo systemctl reset-failed
```

### 2. apt update 超时

优先检查网络和 DNS：

```bash
ip route
cat /etc/resolv.conf
ping -c 2 1.1.1.1
getent hosts ports.ubuntu.com
```

如果 IPv6 解析优先但没有 IPv6 路由，可以强制 apt 走 IPv4：

```bash
sudo tee /etc/apt/apt.conf.d/99local-network.conf >/dev/null <<'EOF'
Acquire::ForceIPv4 "true";
Acquire::Retries "3";
Acquire::http::Pipeline-Depth "0";
Acquire::https::Pipeline-Depth "0";
EOF
```

### 3. GUI 启不来

检查：

```bash
systemctl status gdm3 --no-pager
journalctl -u gdm3 -b --no-pager | tail -100
```

尝试重装 GNOME display manager：

```bash
sudo apt-get install --reinstall gdm3 ubuntu-session gnome-shell
sudo systemctl enable gdm3
sudo systemctl restart gdm3
```

### 4. GPIO 只能 sudo 访问

确认规则和权限：

```bash
id
ls -l /dev/gpiochip*
cat /etc/udev/rules.d/99-gpio-permissions.rules
```

如果用户刚加入 `gpio` 组，需要注销后重新登录。

### 5. 不要恢复 NVIDIA bionic repo

升级到 focal 后，系统 userland 已经不是官方 JetPack 4.x 目标环境。除非你非常清楚依赖关系，否则不要把 NVIDIA R32 的 apt 源直接恢复到 focal 系统里混用。

## 最小命令清单

下面是压缩版流程，适合已经理解风险的人：

```bash
# 0. check
cat /etc/os-release
uname -a
cat /etc/nv_tegra_release
findmnt -no SOURCE,TARGET,FSTYPE /

# 1. hold L4T
sudo apt-mark hold $(dpkg-query -W -f='${binary:Package}\n' 'nvidia-l4t-*')
apt-mark showhold | grep -c '^nvidia-l4t-'

# 2. clean current 18.04
sudo apt-get update
sudo dpkg --configure -a
sudo apt-get -f install
sudo apt-get dist-upgrade
sudo apt-get autoremove --purge

# 3. release upgrade
sudo apt-get install -y update-manager-core ubuntu-release-upgrader-core
sudo do-release-upgrade

# 4. repair after upgrade
sudo dpkg --configure -a
sudo apt-get -f install
sudo apt-get dist-upgrade
sudo apt-get autoremove --purge

# 5. switch focal ubuntu-ports mirror if needed
sudo cp -a /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)
sudo sed -i 's|http://ports.ubuntu.com/ubuntu-ports|https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports|g' /etc/apt/sources.list
sudo tee /etc/apt/apt.conf.d/99local-network.conf >/dev/null <<'EOF'
Acquire::ForceIPv4 "true";
Acquire::Retries "3";
Acquire::http::Pipeline-Depth "0";
Acquire::https::Pipeline-Depth "0";
EOF
sudo apt-get update

# 6. reboot and verify
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

## 本机最终状态

```text
Ubuntu 20.04.6 LTS
Linux 4.9.337-tegra
L4T R32.7.6
rootfs: /dev/mmcblk2p1
gdm3: active
ssh: active
NetworkManager: active
docker: active
containerd: active
system state: running
failed units: 0
held nvidia-l4t packages: 26
GPIO chips: gpiochip0..gpiochip3
```

## 建议用途

这个方案适合：

- 手持 Linux 开发终端。
- SSH 开发机。
- GPIO / I2C / 基础硬件控制。
- Docker / Node.js / Python / CLI 工具。
- 不依赖完整 NVIDIA AI stack 的轻量开发环境。

不建议用于：

- 需要官方 JetPack 完整兼容性的 CUDA/TensorRT/DeepStream 项目。
- 生产环境。
- 无法接受重新刷机恢复的场景。

