#!/usr/bin/env bash
set -euo pipefail

mirror="${1:-https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root via sudo." >&2
  exit 1
fi

backup="/etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)"
cp -a /etc/apt/sources.list "$backup"
echo "backup=$backup"

python3 - "$mirror" <<'PY'
import re
import sys
from pathlib import Path

mirror = sys.argv[1].rstrip("/")
p = Path("/etc/apt/sources.list")
s = p.read_text()
s = re.sub(r'https?://[^ \t]+/ubuntu-ports/?', mirror + '/', s)
p.write_text(s)
PY

cat >/etc/apt/apt.conf.d/99local-network.conf <<'EOF'
Acquire::ForceIPv4 "true";
Acquire::Retries "3";
Acquire::http::Pipeline-Depth "0";
Acquire::https::Pipeline-Depth "0";
EOF

grep -nE '^[[:space:]]*deb ' /etc/apt/sources.list
apt-get update

