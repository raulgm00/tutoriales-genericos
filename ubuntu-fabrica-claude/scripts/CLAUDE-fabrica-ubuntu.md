# Esta máquina es la FÁBRICA (Ubuntu 24.04, dual-boot con Windows)

Eres Claude Code corriendo en la **PC de escritorio de Raúl arrancada en Ubuntu**: Ryzen 9 7900X · 48 GB DDR5 · RTX 5070 Ti (driver `nvidia-driver-580-open`). Su papel es ser la **Fábrica de Software con Agentes** (obreros 24/7). **No es el centro de operaciones**: el centro de operaciones es la **Mac de Raúl** (por SSH sobre Tailscale), desde donde él manda por SSH.

## Quién es Raúl y cómo trabajar con él
- Programa con los ojos (eye-tracking); teclear le cuesta. Respuestas claras y cálidas, sin rodeos; comandos listos de una sola línea; ejecuto yo lo que se pueda.
- Siempre en español con acentos. Decir de frente lo que no es viable, con la alternativa real.
- **Respaldar antes de cambiar**: anotar el estado previo (archivo/log con fecha) antes de tocar cualquier configuración y decirle dónde quedó.
- **Verificar el efecto, no solo el archivo**: nada se da por hecho hasta comprobarlo end-to-end; si no se puede comprobar, decirlo.
- **Comandos largos o multilínea → script** (`.sh` idempotente con `trap`), nunca bloques para pegar.
- Modelo por defecto: `claude-opus-4-8[1m]` (ID exacto + sufijo `[1m]`); Fable 5 solo con acuerdo previo. **Sin API keys**: todo por suscripción.

## A quién reporta la fábrica
1. **Monitor WeSoft (en la nube)** → `https://monitor.wesoft.solutions`, pestaña **Tareas Diarias**. Esta máquina es un **"padre"** más (como Windows y la Mac):
   - Escribe **solo el skill `/cierre`** (punto de regreso cifrado). Lee el hook `SessionStart` (`~/.monitor-hooks/sessionstart-pendientes.mjs`).
   - Variables en `~/.bashrc` (bloque `monitor-wesoft`): `MONITOR_URL`, `MONITOR_ROOT`, `CF_ACCESS_CLIENT_ID/SECRET` (token `monitor-ubuntu`), `MONITOR_SECRETS_PASSPHRASE`. Nunca las imprimas ni las pidas por chat.
   - Contrato completo: `/mnt/c/GitHub/base-conocimiento-mac-windows-ubuntu/Monitor/04-contrato-alimentacion.md`.
2. **Bandeja del CEO** → los obreros escalan dudas a `/api/bandeja-ceo` del Monitor + aviso Telegram (bot Hermes). Ningún agente escribe en `main` sin el GO de Raúl (cadena: Auditor recomienda → CEO autoriza → Mergeador ejecuta).
3. **Linear** (backlog) y **Notion** (PRD, plan "Migracion Linux-Mac"): se leen desde el control plane (Mac), no desde los obreros.

## Cómo se levanta la fábrica
- Skill global `fabrica-agentes` (`~/.claude/skills/fabrica-agentes/`, plantillas en `templates/`): obreros Docker `fabrica-obrero:latest` con **consola partida** (T1 Ejecutor + T2 Auditor en tmux), lanzados con `spawn-obrero.sh N` copiando `~/.claude/.credentials.json` (suscripción).
- Roles: CEO (Raúl) → Orquestador (control plane) → Obreros → Mergeador → CodeRabbit. Detalle en la memoria `fabrica-software-obreros`.
- Fase siguiente del plan: obreros en **Incus** (Fase 7 en Notion).

## Discos y rutas
- Disco de Windows (C:) montado en `/mnt/c` (NTFS, `ntfs3`). Los repos viven ahí: `/mnt/c/GitHub/SitiosWeb/...`. **No muevas repos ni videos**: se leen en sitio.
- Las academias tienen **43 junctions** `skill-web/.<academia>` → `D:`/`F:`; en Ubuntu son symlinks sobre esas unidades montadas (pendiente recrearlos; los videos no se mueven).
- Base de conocimiento por SO: `/mnt/c/GitHub/base-conocimiento-mac-windows-ubuntu/` → carpeta `Ubuntu/` (esta máquina) y `Monitor/`. **No commitear** ese repo sin revisión de Raúl.
- Las skills copiadas de Windows traen rutas `C:\...`; tradúcelas a `/mnt/c/...`.

## Hardware: honestidad
- Los crashes 0x116/BSOD de Windows son de **plataforma** (fuente PX1200G / EXPO), no de la GPU; en Linux reaparecerían como `Xid 79`. Si pasa, no es "bug de Ubuntu".
- Partición de Ubuntu: **24 GB** (nvme0n1p5). Es poca para Docker/Incus: antes de escalar obreros, ampliar (o montar `/var/lib/docker` en otra partición).
