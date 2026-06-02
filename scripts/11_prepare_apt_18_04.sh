#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "== update and repair current release =="
sudo apt-get update
sudo dpkg --configure -a
sudo apt-get -f install
sudo apt-get dist-upgrade
sudo apt-get autoremove --purge
sudo apt-get clean

echo "== install release upgrader =="
sudo apt-get install -y update-manager-core ubuntu-release-upgrader-core

echo "== release-upgrades setting =="
grep '^Prompt=' /etc/update-manager/release-upgrades || true

echo "== final pre-upgrade checks =="
sudo dpkg --audit || true
sudo apt-get -s -f install
apt-mark showhold | grep -c '^nvidia-l4t-' | awk '{print "held_l4t="$1}'

