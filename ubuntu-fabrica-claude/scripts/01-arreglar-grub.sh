#!/usr/bin/env bash
# 01-arreglar-grub.sh — GRUB con MENÚ (Ubuntu + Windows), Ubuntu primero en la NVRAM UEFI y reloj en UTC.
# Idempotente. Respalda /etc/default/grub antes de tocarlo. Correr DENTRO de Ubuntu:  bash 01-arreglar-grub.sh
set -uo pipefail
ts=$(date +%Y%m%d-%H%M%S)
echo "== Arreglo de GRUB / UEFI / reloj — $ts =="
sudo -v || { echo "necesito sudo"; exit 1; }

# --- 1) GRUB: menú visible 10 s y detectar Windows (Ubuntu 24.04 trae os-prober APAGADO) ---
sudo cp /etc/default/grub "/etc/default/grub.bak-$ts" && echo "respaldo: /etc/default/grub.bak-$ts"
set_kv() {
  if grep -q "^$1=" /etc/default/grub; then sudo sed -i "s|^$1=.*|$1=$2|" /etc/default/grub
  else echo "$1=$2" | sudo tee -a /etc/default/grub >/dev/null; fi
}
set_kv GRUB_TIMEOUT_STYLE menu
set_kv GRUB_TIMEOUT 10
set_kv GRUB_DISABLE_OS_PROBER false
command -v os-prober >/dev/null 2>&1 || sudo apt-get install -y os-prober
sudo os-prober || true
sudo update-grub
if grep -qi "windows boot manager" /boot/grub/grub.cfg; then
  echo "✓ Windows aparece en el menú de GRUB"
else
  echo "✗ Windows NO apareció en grub.cfg — revisa: sudo os-prober (¿ve la ESP de Windows?)"
fi

# --- 2) NVRAM UEFI: entrada 'ubuntu' primero (lo mismo que bcdedit desde Windows) ---
command -v efibootmgr >/dev/null 2>&1 || sudo apt-get install -y efibootmgr
echo "--- orden UEFI antes ---"; sudo efibootmgr | grep -E "BootOrder|Boot[0-9A-F]{4}"
UB=$(sudo efibootmgr | grep -i "ubuntu" | head -1 | sed -E 's/^Boot([0-9A-F]{4}).*/\1/')
ORDER=$(sudo efibootmgr | grep "^BootOrder:" | awk '{print $2}')
if [ -n "$UB" ] && [ -n "$ORDER" ]; then
  REST=$(echo "$ORDER" | tr ',' '\n' | grep -v "^$UB$" | paste -sd, -)
  NEW="$UB${REST:+,$REST}"
  sudo efibootmgr -o "$NEW" >/dev/null && echo "✓ BootOrder = $NEW (ubuntu primero)"
else
  echo "✗ no encontré la entrada 'ubuntu' en efibootmgr (¿arrancaste en modo UEFI?)"
fi

# --- 3) Reloj: RTC en UTC (Windows ya está en UTC con RealTimeIsUniversal=1) ---
sudo timedatectl set-local-rtc 0 --adjust-system-clock
sudo timedatectl set-ntp true
timedatectl | grep -E "Local time|RTC in local|NTP service|System clock synchronized"
echo "== Listo. Si al reiniciar Windows vuelve a ponerse primero: fíjalo en la BIOS (MSI Click BIOS X → Boot → UEFI Hard Disk Drive BBS Priorities → #1 ubuntu). =="
