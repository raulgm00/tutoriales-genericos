# Arranque de Ubuntu (la Fábrica) — paquete del 2026-09-08

## Hecho hoy desde Windows (no hay que repetirlo)
- **Orden UEFI**: Ubuntu (GRUB) otra vez PRIMERO y el **siguiente arranque forzado a GRUB**. Log: `fijar-grub-*.log` en esta carpeta. (El arreglo del 07-sep se había revertido solo: Windows volvió a ponerse primero.)
- **Reloj**: Windows ya usa UTC (`RealTimeIsUniversal=1`); en el arranque de hoy NO hubo salto de 6 h.

## Al reiniciar
1. Debe salir el **menú morado de GRUB**. Si entra directo a Windows → arréglalo en la **BIOS** (abajo); es lo único duradero.
2. Si GRUB entra **directo a Ubuntu sin menú y sin Windows**: es normal en Ubuntu 24.04 (os-prober viene apagado). Lo corrige el script 01.

## Dentro de Ubuntu (Ctrl+Alt+T), tres líneas
```
sudo mkdir -p /mnt/c && sudo mount -t ntfs3 -o uid=$(id -u),gid=$(id -g) /dev/nvme0n1p2 /mnt/c
bash /mnt/c/tmp/arranque-ubuntu/01-arreglar-grub.sh
bash /mnt/c/tmp/arranque-ubuntu/02-primer-arranque-claude.sh
```
- Si el `mount` falla, C: puede ser `/dev/nvme1n1p2` (míralo con `lsblk -o NAME,SIZE,FSTYPE,LABEL`; C: mide 1.88 TB).
- **01** = GRUB con menú + Windows, Ubuntu primero en UEFI, reloj UTC.
- **02** = Claude Code logueado por suscripción, `~/.claude/CLAUDE.md` con la identidad de la Fábrica, memoria + skills de Windows, padre del Monitor (hook SessionStart + `/cierre`). Al final te dice qué secretos rellenar en `~/.bashrc`.
- Copia idéntica del paquete en el repo base: `GitHub/base-conocimiento-mac-windows-ubuntu/Ubuntu/02-primer-arranque-fabrica/`.

## BIOS (MSI Click BIOS X) — fix duradero del orden de arranque
Settings → Boot → **UEFI Hard Disk Drive BBS Priorities** → Boot Option #1 = **ubuntu** (Predator SSD GM9). Luego, arriba, Boot Option #1 = "UEFI Hard Disk: ubuntu". F10 para guardar.

## OJO — la partición de Ubuntu quedó de 24 GB
Se había decidido 250–400 GB; el instalador dejó `nvme0n1p5` de **24 GB**. Alcanza para arrancar y probar, NO para Docker/Incus con obreros. Antes de escalar: encoger C: y ampliar/mover con GParted desde el USB, o montar `/var/lib/docker` en otra partición.
