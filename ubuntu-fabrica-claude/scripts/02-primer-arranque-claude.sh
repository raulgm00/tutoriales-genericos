#!/usr/bin/env bash
# 02-primer-arranque-claude.sh — convierte este Ubuntu en la FÁBRICA de Raúl:
#   Claude Code logueado (sesión de suscripción copiada de Windows, sin API keys), CLAUDE.md de la fábrica,
#   memoria y skills traídas de Windows, y "padre" del Monitor WeSoft (hook SessionStart + /cierre).
# Idempotente. NO pide ni imprime secretos. sudo solo si falta node.   Uso:  bash 02-primer-arranque-claude.sh
set -uo pipefail
ts=$(date +%Y%m%d-%H%M%S)
LOG="$HOME/primer-arranque-fabrica-$ts.log"
exec > >(tee -a "$LOG") 2>&1
echo "== Primer arranque de la Fábrica — $ts =="

# 1) disco de Windows (C:)
WIN=""
for m in /mnt/c /media/"$USER"/* /mnt/*; do
  if [ -d "$m/Users/rgarc/.claude" ]; then WIN="$m"; break; fi
done
if [ -z "$WIN" ]; then
  echo "✗ No encuentro el disco de Windows (C:) montado. Móntalo y vuelve a correr este script:"
  echo "   sudo mkdir -p /mnt/c && sudo mount -t ntfs3 -o uid=\$(id -u),gid=\$(id -g) /dev/nvme0n1p2 /mnt/c"
  echo "   (si falla prueba /dev/nvme1n1p2; míralo con: lsblk -o NAME,SIZE,FSTYPE,LABEL)"
  exit 1
fi
echo "✓ Windows en: $WIN"
WCL="$WIN/Users/rgarc/.claude"
AQUI="$(cd "$(dirname "$0")" && pwd)"
KB="$WIN/GitHub/base-conocimiento-mac-windows-ubuntu"

# 2) Node >= 18 y Claude Code
if ! command -v node >/dev/null 2>&1 || [ "$(node -p 'process.versions.node.split(".")[0]')" -lt 18 ]; then
  echo "→ Instalando Node 22 (NodeSource)…"
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt-get install -y nodejs
fi
echo "✓ node $(node -v)"
if ! command -v claude >/dev/null 2>&1; then
  echo "→ Instalando Claude Code…"
  curl -fsSL https://claude.ai/install.sh | bash
fi
export PATH="$HOME/.local/bin:$PATH"
grep -q '.local/bin' "$HOME/.bashrc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
echo "✓ claude $(claude --version 2>/dev/null || echo '(abre una terminal nueva para verlo)')"

# 3) sesión de suscripción: copiar credenciales de Windows si aquí no hay
mkdir -p "$HOME/.claude" && chmod 700 "$HOME/.claude"
if [ ! -f "$HOME/.claude/.credentials.json" ] && [ -f "$WCL/.credentials.json" ]; then
  cp "$WCL/.credentials.json" "$HOME/.claude/" && chmod 600 "$HOME/.claude/.credentials.json" && echo "✓ credenciales de suscripción copiadas"
else
  echo "· credenciales: ya existían aquí (o no hay en Windows)"
fi

# 4) saltar el onboarding (tema + confianza en carpetas), como en los obreros Docker
if [ ! -f "$HOME/.claude.json" ]; then
  node -e "const h=process.env.HOME;require('fs').writeFileSync(h+'/.claude.json',JSON.stringify({hasCompletedOnboarding:true,theme:'dark',bypassPermissionsModeAccepted:true,projects:{[h]:{hasTrustDialogAccepted:true}}},null,2))"
  echo "✓ ~/.claude.json sembrado (sin asistente de tema)"
fi

# 5) settings.json mínimo con el modelo fijo (doble candado) si no existe
if [ ! -f "$HOME/.claude/settings.json" ]; then
cat > "$HOME/.claude/settings.json" <<'JSON'
{
  "model": "claude-opus-4-8[1m]",
  "env": {
    "ANTHROPIC_MODEL": "claude-opus-4-8[1m]",
    "CLAUDE_CODE_DISABLE_MOUSE_CLICKS": "1",
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "60"
  },
  "effortLevel": "high"
}
JSON
  echo "✓ settings.json creado (Opus 4.8 [1m] con doble candado)"
else
  echo "· settings.json ya existía (no lo toco)"
fi

# 6) CLAUDE.md global = identidad de la Fábrica
[ -f "$HOME/.claude/CLAUDE.md" ] && cp "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md.bak-$ts"
cp "$AQUI/CLAUDE-fabrica-ubuntu.md" "$HOME/.claude/CLAUDE.md" && echo "✓ ~/.claude/CLAUDE.md = identidad de la Fábrica"

# 7) memoria de Windows → memoria del proyecto HOME de aquí (solo lo que falte)
MEMW="$WCL/projects/C--Users-rgarc/memory"
MEMU="$HOME/.claude/projects/$(echo "$HOME" | sed 's#[^A-Za-z0-9]#-#g')/memory"
mkdir -p "$MEMU"; n=0
for f in "$MEMW"/*.md; do
  if [ ! -e "$MEMU/$(basename "$f")" ]; then cp "$f" "$MEMU/"; n=$((n+1)); fi
done
echo "✓ memoria: $n archivos nuevos → $MEMU ($(ls "$MEMU" | wc -l) en total)"

# 8) skills de Windows (solo las que faltan)
mkdir -p "$HOME/.claude/skills"; s=0
for d in "$WCL"/skills/*/; do
  b=$(basename "$d")
  if [ ! -d "$HOME/.claude/skills/$b" ]; then cp -r "$d" "$HOME/.claude/skills/"; s=$((s+1)); fi
done
echo "✓ skills: $s copiadas (traen rutas C:\\ — Claude las traduce a /mnt/c)"

# 9) padre del Monitor WeSoft (hook SessionStart + /cierre en la nube)
if [ -d "$KB/Monitor/portable" ]; then
  mkdir -p "$HOME/monitor-portable" && cp "$KB"/Monitor/portable/* "$HOME/monitor-portable/" && bash "$HOME/monitor-portable/instalar-padre.sh"
else
  echo "✗ no encuentro $KB/Monitor/portable (¿el repo base está en C:\\GitHub?)"
fi

echo
echo "== LISTO. Te queda a ti (secretos; nunca los toco): =="
echo " 1) nano ~/.bashrc → rellenar CF_ACCESS_CLIENT_ID / CF_ACCESS_CLIENT_SECRET (token 'monitor-ubuntu' de Zero Trust) y MONITOR_SECRETS_PASSPHRASE"
echo " 2) terminal nueva → claude → debe abrir en 'Opus 4.8 (1M)' sin pedir login"
echo " 3) en un proyecto: /cierre → 'publicado CIFRADO'. Sesión nueva → SessionStart lo inyecta"
echo "Log: $LOG"
