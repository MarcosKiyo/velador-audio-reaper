#!/bin/sh
# Instala Agent Cable en REAPER (macOS). Requisitos: REAPER 7, ReaImGui, Claude Code logueado (`claude`), python3 + numpy + scipy + ffmpeg.
set -e
AQUI="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/Library/Application Support/REAPER/Scripts/AgentCable"
mkdir -p "$DEST/work" "$DEST/bin" "$DEST/run"
cp "$AQUI/AgentCable.lua" "$AQUI/lanzar.sh" "$AQUI/auth.sh" "$DEST/"; cp "$AQUI"/bin/* "$DEST/bin/"; cp "$AQUI"/work/* "$DEST/work/"
chmod +x "$DEST/lanzar.sh" "$DEST/auth.sh" "$DEST/bin/cable"
echo "Copiado en $DEST"
echo "En REAPER: Actions > Show action list > New action > Load ReaScript > AgentCable/AgentCable.lua, y ejecutalo."
