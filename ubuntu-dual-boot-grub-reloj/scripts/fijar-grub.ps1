# Pone la entrada UEFI "ubuntu" (GRUB) al frente del orden de arranque y fuerza el siguiente arranque a GRUB.
# Idempotente: si ya está primero, solo lo reporta. Deja log con el estado ANTES y DESPUÉS.
$ErrorActionPreference = 'Continue'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$dir = 'C:\tmp\arranque-ubuntu'
$log = "$dir\fijar-grub-$stamp.log"
Start-Transcript -Path $log -Force | Out-Null
try {
  "=== ANTES: {fwbootmgr} ==="
  $antes = bcdedit /enum '{fwbootmgr}'; $antes
  Copy-Item -Path $log -Destination "$dir\uefi-orden-respaldo-$stamp.txt" -ErrorAction SilentlyContinue
  "=== ENTRADAS firmware ==="
  $fw = bcdedit /enum firmware; $fw
  $ids = @(); $cur = $null
  foreach ($l in $fw) {
    if ($l -match '^(identificador|identifier)\s+(\{[^}]+\})') { $cur = $matches[2] }
    elseif ($l -match '^(descripci.n|description)\s+(.+)$' -and $cur) { $ids += [pscustomobject]@{ id = $cur; desc = $matches[2].Trim() }; $cur = $null }
  }
  "=== RESUMEN entradas ==="; $ids | Format-Table -AutoSize | Out-String
  $ub = ($ids | Where-Object { $_.desc -match 'ubuntu' } | Select-Object -First 1).id
  if (-not $ub) { throw "No encontré ninguna entrada 'ubuntu' en el firmware. GRUB no está registrado en la NVRAM." }
  "Entrada Ubuntu = $ub"
  $orden = ($antes | Where-Object { $_ -match '^(displayorder|orden de presentaci)' } | Select-Object -First 1)
  $primera = ($antes | Where-Object { $_ -match '\{[0-9a-f-]{36}\}|\{bootmgr\}' } | Select-Object -First 1)
  "Primera entrada actual: $primera"
  bcdedit /set '{fwbootmgr}' displayorder $ub /addfirst
  "displayorder /addfirst -> exit $LASTEXITCODE"
  bcdedit /set '{fwbootmgr}' bootsequence $ub
  "bootsequence (solo el siguiente arranque) -> exit $LASTEXITCODE"
  "=== DESPUES: {fwbootmgr} ==="
  bcdedit /enum '{fwbootmgr}'
  "RESULTADO: OK"
} catch {
  "RESULTADO: ERROR $_"
} finally {
  Stop-Transcript | Out-Null
}
