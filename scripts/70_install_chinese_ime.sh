#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "== install Chinese IME =="
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  ibus-libpinyin \
  libpinyin-data \
  language-pack-zh-hans \
  language-pack-gnome-zh-hans \
  fonts-noto-cjk \
  fonts-wqy-microhei \
  fonts-wqy-zenhei

im-config -n ibus || true

echo "== profile input env =="
if ! grep -q 'Chinese input method' "$HOME/.profile"; then
  cat >>"$HOME/.profile" <<'EOF'

# Chinese input method
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
EOF
fi

echo "== GNOME input source =="
if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'libpinyin')]" || true
  gsettings set org.gnome.desktop.input-sources mru-sources "[('ibus', 'libpinyin'), ('xkb', 'us')]" || true
fi

ibus restart || true
ibus list-engine | grep -Ei 'libpinyin|pinyin|Chinese|中文' || true

echo "Log out and log back in if the input method does not appear immediately."

