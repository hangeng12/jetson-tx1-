#!/usr/bin/env bash
set -euo pipefail

echo "This starts the interactive Ubuntu release upgrade."
echo "Run inside tmux/screen or keep a local console available."
echo "nvidia-l4t packages should already be held."
echo
apt-mark showhold | grep '^nvidia-l4t-' || {
  echo "No held nvidia-l4t packages found. Stop and hold them first." >&2
  exit 1
}

sudo do-release-upgrade

