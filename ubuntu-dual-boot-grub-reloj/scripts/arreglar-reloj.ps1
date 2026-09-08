# arreglar-reloj.ps1 — corrige el reloj de Windows (estaba 6 h atrasado) y deja el servicio de hora en automático.
# Causa: RealTimeIsUniversal=1 se activó cuando el RTC aún tenía hora LOCAL, y el servicio w32time estaba parado.
# Idempotente. Log con ANTES/DESPUÉS en C:\tmp\arranque-ubuntu\.
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = "C:\tmp\arranque-ubuntu\arreglar-reloj-$stamp.log"
Start-Transcript -Path $log -Force | Out-Null
try {
  "=== ANTES ==="
  "Hora Windows : " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')
  "w32time      : " + ((Get-Service w32time).Status) + " / " + ((Get-Service w32time).StartType)
  # 1) hora real desde internet (cabecera Date, UTC)
  $resp = Invoke-WebRequest -Uri 'https://www.google.com' -Method Head -UseBasicParsing -TimeoutSec 15
  $utc = [DateTime]::ParseExact($resp.Headers['Date'], 'ddd, dd MMM yyyy HH:mm:ss \G\M\T', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal)
  $real = $utc.ToLocalTime()
  "Hora real    : " + $real.ToString('yyyy-MM-dd HH:mm:ss K')
  $dif = [math]::Round(($real - (Get-Date)).TotalMinutes)
  "Diferencia   : $dif minutos"
  if ([math]::Abs($dif) -ge 2) { Set-Date -Date $real | Out-Null; "-> hora corregida con Set-Date" } else { "-> diferencia pequeña, no toco la hora a mano" }
  # 2) servicio de hora en automático + sincronización
  Set-Service w32time -StartupType Automatic
  Start-Service w32time
  w32tm /config /manualpeerlist:"time.windows.com,0x9 pool.ntp.org,0x9" /syncfromflags:manual /reliable:no /update | Out-Null
  Start-Sleep 2
  w32tm /resync /force
  "=== DESPUÉS ==="
  "Hora Windows : " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')
  "w32time      : " + ((Get-Service w32time).Status) + " / " + ((Get-Service w32time).StartType)
  w32tm /query /status | Select-String 'Origen|Source|Última|Last Successful'
  "RealTimeIsUniversal: " + (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation').RealTimeIsUniversal
  "RESULTADO: OK"
} catch { "RESULTADO: ERROR $_" } finally { Stop-Transcript | Out-Null }
