#!/usr/bin/env bash
set -euo pipefail

echo "== disable unused dhcp server services if present =="
for svc in isc-dhcp-server.service isc-dhcp-server6.service; do
  if systemctl list-unit-files "$svc" >/dev/null 2>&1; then
    sudo systemctl disable --now "$svc" || true
  fi
  sudo systemctl reset-failed "$svc" || true
done
sudo systemctl reset-failed || true

echo "== archive crash reports =="
if [ -d /var/crash ]; then
  sudo mkdir -p /var/crash/archived-after-upgrade
  shopt -s nullglob
  for f in /var/crash/*; do
    [ "$f" = "/var/crash/archived-after-upgrade" ] && continue
    sudo mv "$f" /var/crash/archived-after-upgrade/ || true
  done
fi

echo "== status =="
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

