#!/usr/bin/env bash
# Baixa o Godot headless (Linux) para $HOME/godot/godot. Versão via GODOT_VERSION/GODOT_CHANNEL.
set -euo pipefail
V="${GODOT_VERSION:-4.5}"
CH="${GODOT_CHANNEL:-stable}"
BASE="https://github.com/godotengine/godot/releases/download/${V}-${CH}"
mkdir -p "$HOME/godot"
cd "$HOME/godot"
if [ ! -x ./godot ]; then
  curl -fsSL -o godot.zip "${BASE}/Godot_v${V}-${CH}_linux.x86_64.zip"
  unzip -q -o godot.zip
  mv "Godot_v${V}-${CH}_linux.x86_64" godot
  chmod +x godot
  rm -f godot.zip
fi
./godot --version
if [ -n "${GITHUB_PATH:-}" ]; then echo "$HOME/godot" >> "$GITHUB_PATH"; fi
