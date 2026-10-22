#!/bin/bash
# lanzar.sh <archivo_pedido> <salida.jsonl> <carpeta_trabajo> [session_id]
# Corre Claude Code en segundo plano (con la cuenta de Claude del propio usuario). Solo puede usar el comando `cable`, leer y listar.
export USER="${USER:-$(id -un)}"; export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
B="$(cd "$(dirname "$0")" && pwd)"
export CABLE_RUN="$B/run"; export PATH="$B/bin:$PATH"
PEDIDO="$1"; OUT="$2"; cd "$3" || exit 1
RES=""; [ -n "$4" ] && RES="--resume $4"
# carpetas de samples del usuario (una ruta por linea en samples.cfg): se pueden LEER, nunca escribir
ADD=(); DENY=(Edit NotebookEdit)
if [ -f "$B/samples.cfg" ]; then
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    ADD+=(--add-dir "$d"); DENY+=("Write($d/**)")
  done < "$B/samples.cfg"
fi
MOD="${5:-claude-opus-5-5}"; EFF="${6:-medium}"
(
  claude -p "$(cat "$PEDIDO")" --output-format stream-json --verbose --model "$MOD" --effort "$EFF" $RES \
    --setting-sources project --strict-mcp-config --disable-slash-commands \
    "${ADD[@]}" \
    --allowedTools "Bash(cable:*)" "Read" "Glob" "Grep" \
    --disallowedTools "${DENY[@]}" \
    --append-system-prompt "$(cat "$B/work/INSTRUCCIONES.md")" \
    >> "$OUT" 2>> "$OUT.err"
  echo "__FIN__ $?" >> "$OUT"
) >/dev/null 2>&1 &
exit 0
