#!/usr/bin/env bash
set -u

echo "== boot/os =="
date -Is
uptime
cat /etc/os-release | sed -n '1,8p'
uname -a
cat /etc/nv_tegra_release 2>/dev/null || true

echo "== rootfs/resources =="
findmnt -no SOURCE,TARGET,FSTYPE /
df -h /
free -h

echo "== services =="
systemctl is-system-running || true
systemctl --failed --no-pager || true
for svc in ssh NetworkManager gdm3 docker containerd; do
  printf "%s " "$svc"
  systemctl is-active "$svc" || true
done

echo "== apt/dpkg =="
apt list --upgradable 2>/dev/null | tail -n +2 | wc -l | awk '{print "upgradable="$1}'
apt-mark showhold | grep -c '^nvidia-l4t-' | awk '{print "held_l4t="$1}'
sudo dpkg --audit || true
sudo apt-get -s -f install

echo "== gpio =="
id
ls -l /dev/gpiochip* 2>/dev/null || true
ls -d /sys/class/gpio 2>/dev/null || true

