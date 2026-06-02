#!/usr/bin/env bash
set -euo pipefail

backup_dir="$HOME/tx1_upgrade_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

echo "== system info =="
hostname | tee "$backup_dir/hostname.txt"
whoami | tee "$backup_dir/whoami.txt"
pwd | tee "$backup_dir/pwd.txt"
uname -a | tee "$backup_dir/uname.txt"
cat /etc/os-release | tee "$backup_dir/os-release.txt"
cat /etc/nv_tegra_release 2>/dev/null | tee "$backup_dir/nv_tegra_release.txt" || true
findmnt | tee "$backup_dir/findmnt.txt"
df -h | tee "$backup_dir/df-h.txt"
free -h | tee "$backup_dir/free-h.txt"

echo "== apt state =="
apt-mark showhold | tee "$backup_dir/apt-holds-before.txt"
dpkg -l 'nvidia-l4t-*' | tee "$backup_dir/nvidia-l4t-packages.txt" || true
sudo dpkg --audit | tee "$backup_dir/dpkg-audit-before.txt" || true
sudo apt-get -s -f install | tee "$backup_dir/apt-f-sim-before.txt"

echo "== backup apt and boot metadata =="
cp -a /etc/apt "$backup_dir/etc-apt"
sudo cp -a /boot "$backup_dir/boot"

echo "== hold nvidia-l4t packages =="
mapfile -t l4t_packages < <(dpkg-query -W -f='${binary:Package}\n' 'nvidia-l4t-*' 2>/dev/null || true)
if [ "${#l4t_packages[@]}" -eq 0 ]; then
  echo "No nvidia-l4t packages found. This does not look like a normal L4T system." >&2
  exit 1
fi
sudo apt-mark hold "${l4t_packages[@]}"
apt-mark showhold | grep '^nvidia-l4t-' | tee "$backup_dir/apt-holds-after.txt"
echo "held_l4t=$(apt-mark showhold | grep -c '^nvidia-l4t-' || true)"

tarball="$HOME/$(basename "$backup_dir").tar.gz"
tar -czf "$tarball" -C "$HOME" "$(basename "$backup_dir")"
echo "backup_tarball=$tarball"

