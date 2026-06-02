#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "== reinstall appstream =="
sudo apt-get install -y --reinstall appstream || true
appstreamcli --version || true

echo "== restore apt appstream hook if dpkg-dist exists =="
if [ -f /etc/apt/apt.conf.d/50appstream.dpkg-dist ]; then
  sudo cp -a /etc/apt/apt.conf.d/50appstream "/etc/apt/apt.conf.d/50appstream.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
  sudo cp -a /etc/apt/apt.conf.d/50appstream.dpkg-dist /etc/apt/apt.conf.d/50appstream
fi

sudo apt-get update || true
sudo appstreamcli refresh-cache --force || true

