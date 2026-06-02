#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "== post-upgrade repair =="
sudo dpkg --configure -a || sudo dpkg --force-confold --configure -a
sudo apt-get -f install
sudo apt-get dist-upgrade
sudo apt-get autoremove --purge
sudo apt-get clean

echo "== chromium cleanup if broken =="
if dpkg --audit | grep -qi chromium; then
  sudo apt-get remove --purge chromium-browser chromium-browser-l10n || true
  sudo dpkg --configure -a || true
  sudo apt-get -f install
fi

echo "== checks =="
cat /etc/os-release | sed -n '1,8p'
uname -a
cat /etc/nv_tegra_release 2>/dev/null || true
apt-mark showhold | grep -c '^nvidia-l4t-' | awk '{print "held_l4t="$1}'
sudo dpkg --audit || true
sudo apt-get -s -f install

