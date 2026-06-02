#!/usr/bin/env bash
set -euo pipefail

echo "== user =="
id

echo "== sudo =="
sudo -v
sudo true
echo "sudo_ok=1"

