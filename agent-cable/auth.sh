#!/bin/sh
# auth.sh status|login : estado del Claude Code del usuario y apertura del inicio de sesion OFICIAL en la Terminal.
# Agent Cable nunca ve, guarda ni reenvia credenciales ni codigos: el login lo completa el usuario con el Claude Code de Anthropic.
export USER="${USER:-$(id -un)}"; export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
B="$(cd "$(dirname "$0")" && pwd)"
case "$1" in
  status)
    ( if claude auth status 2>/dev/null | grep -q '"loggedIn": true'; then echo ok; else echo no; fi > "$B/auth.txt.tmp"; mv "$B/auth.txt.tmp" "$B/auth.txt" ) >/dev/null 2>&1 &
    ;;
  login)
    rm -f "$B/auth.txt"
    osascript -e 'tell application "Terminal" to activate' -e 'tell application "Terminal" to do script "claude auth login; echo; echo Listo. Podes cerrar esta ventana."' >/dev/null 2>&1 &
    ;;
esac
exit 0
