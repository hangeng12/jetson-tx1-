#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "== install dev and gpio tools =="
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  wget \
  xz-utils \
  git \
  ripgrep \
  tmux \
  gpiod \
  libgpiod-dev \
  i2c-tools \
  python3-pip

if apt-cache show python3-libgpiod >/dev/null 2>&1; then
  sudo apt-get install -y --no-install-recommends python3-libgpiod
fi

echo "== gpio permissions =="
sudo groupadd --system gpio 2>/dev/null || true
sudo usermod -aG gpio "$USER"

sudo tee /etc/udev/rules.d/99-gpio-permissions.rules >/dev/null <<'EOF'
KERNEL=="gpiochip*", GROUP="gpio", MODE="0660"
SUBSYSTEM=="gpio", KERNEL=="gpio*", GROUP="gpio", MODE="0660"
EOF

sudo udevadm control --reload-rules || true
sudo udevadm trigger --subsystem-match=gpio || true
sudo chgrp gpio /dev/gpiochip* 2>/dev/null || true
sudo chmod 0660 /dev/gpiochip* 2>/dev/null || true

echo "== verify =="
git --version || true
rg --version | sed -n '1p' || true
tmux -V || true
gpiodetect || true
ls -l /dev/gpiochip* 2>/dev/null || true
id

