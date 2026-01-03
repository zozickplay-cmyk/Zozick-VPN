@echo off
chcp 65001 >nul
title Koala Clash Config Loader

set "THIS_PATH=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c = Get-Content -LiteralPath $env:THIS_PATH -Encoding UTF8; $start = [array]::IndexOf($c, '#___START___'); if ($start -ge 0) { $ps = $c[($start+1)..($c.Count-1)] -join \"`n\"; Invoke-Expression $ps } else { Write-Host 'Ошибка: Метка старта не найдена.' -ForegroundColor Red }"

pause
exit /b

#___START___

$ProfileDir = "$env:APPDATA\io.github.koala-clash\profiles"
Write-Host "=== Koala Clash Final Fixer ===" -ForegroundColor Cyan

if (-not (Test-Path $ProfileDir)) {
    Write-Host "ОШИБКА: Папка profiles не найдена!" -ForegroundColor Red; return
}

$Files = Get-ChildItem -Path $ProfileDir -Filter "*.yaml"
if ($Files.Count -eq 0) { Write-Host "ОШИБКА: Нет конфигов."; return }

Write-Host "`nВыберите режим:" -ForegroundColor Yellow
Write-Host "1. [ИГРЫ] Включить обход (Games + VPN)"
Write-Host "2. [СБРОС] Вернуть стандартные настройки"
$choice = Read-Host "Ваш выбор (1 или 2)"

$CustomConfig = @"
rule-providers:
  my-direct:
    type: http
    behavior: classical
    url: https://gist.githubusercontent.com/zozickplay-cmyk/f0ad4515e577bf1dd5ade61fbbe4f804/raw/games-direct.yaml
    path: ./games-direct.yaml
    interval: 3600
  my-proxy:
    type: http
    behavior: classical
    url: https://gist.githubusercontent.com/zozickplay-cmyk/cc071c085a58a4ea638d783de5c3ab03/raw/vpn-proxy.yaml
    path: ./vpn-proxy.yaml
    interval: 3600
rules:
- NETWORK,UDP,DIRECT
- RULE-SET,my-proxy,Main
- RULE-SET,my-direct,DIRECT
- MATCH,Main
"@

$DefaultConfig = @"
rules:
- MATCH,Main
"@

if ($choice -eq "1") { $NewBottom = $CustomConfig }
elseif ($choice -eq "2") { $NewBottom = $DefaultConfig }
else { Write-Host "Неверный выбор."; return }

$UTF8NoBOM = New-Object System.Text.UTF8Encoding $false

foreach ($File in $Files) {
    $FilePath = $File.FullName
    Write-Host "Обработка: $($File.Name)... " -NoNewline

    try {
        $Content = Get-Content $FilePath -Raw -Encoding UTF8
        
        $Match = [regex]::Match($Content, "(?m)^(rules|rule-providers):")

        if ($Match.Success) {
            $TopPart = $Content.Substring(0, $Match.Index)
            
            $TopPart = $TopPart -replace "(?m)(\s*---\s*|\s+)$", ""
            
            $FinalContent = $TopPart + "`r`n" + $NewBottom
            
            [System.IO.File]::WriteAllText($FilePath, $FinalContent, $UTF8NoBOM)
            
            Write-Host "[OK]" -ForegroundColor Green
        } else {
            Write-Host "[ПРОПУСК]" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[ОШИБКА]: $_" -ForegroundColor Red
    }
}

Write-Host "`n[ГОТОВО] Теперь файл чистый. Перезагрузите Koala Clash." -ForegroundColor Green