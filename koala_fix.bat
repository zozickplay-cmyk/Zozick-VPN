@echo off
chcp 65001 >nul
title Koala Clash Config Manager

:: --- ЗАГРУЗЧИК POWERSHELL (НЕ ТРОГАТЬ) ---
:: Мы передаем путь к этому файлу в переменную окружения, чтобы PowerShell мог его прочитать
set "THIS_PATH=%~f0"

:: Запускаем PowerShell, ищем метку #___START___ и выполняем всё, что ниже неё.
:: Это предотвращает ошибку с "goto", так как PowerShell никогда не увидит верхнюю часть файла.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c = Get-Content -LiteralPath $env:THIS_PATH -Encoding UTF8; $start = [array]::IndexOf($c, '#___START___'); if ($start -ge 0) { $ps = $c[($start+1)..($c.Count-1)] -join \"`n\"; Invoke-Expression $ps } else { Write-Host 'Ошибка: Метка старта не найдена.' -ForegroundColor Red }"

pause
exit /b

#___START___
# --- ОТСЮДА НАЧИНАЕТСЯ POWERSHELL КОД ---

$TargetFile = "$env:APPDATA\io.github.koala-clash\koala-clash.yaml"

Write-Host "=== Koala Clash Rules Manager ===" -ForegroundColor Cyan
Write-Host "Целевой файл: $TargetFile" -ForegroundColor Gray

if (-not (Test-Path $TargetFile)) {
    Write-Host "ОШИБКА: Файл конфигурации не найден!" -ForegroundColor Red
    Write-Host "Сначала запустите приложение Koala Clash один раз, чтобы оно создало файл."
    return
}

Write-Host "`nВыберите действие:" -ForegroundColor Yellow
Write-Host "1. [ИГРЫ] Добавить кастомные правила (VPN + Games)"
Write-Host "2. [СБРОС] Вернуть стандартные настройки (Очистить правила)"
$choice = Read-Host "Введите 1 или 2"

# --- БЛОК 1: Твои кастомные настройки ---
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

# --- БЛОК 2: Дефолтный сброс ---
$DefaultConfig = @"
rules:
- MATCH,Main
"@

# Логика выбора
if ($choice -eq "1") { 
    $NewBottom = $CustomConfig 
    Write-Host "`nПрименяю игровые настройки..." -ForegroundColor Cyan
}
elseif ($choice -eq "2") { 
    $NewBottom = $DefaultConfig 
    Write-Host "`nВозвращаю заводские настройки..." -ForegroundColor Cyan
}
else { 
    Write-Host "Неверный выбор. Закрытие." -ForegroundColor Red; return 
}

# --- ГЛАВНАЯ ЛОГИКА ЗАМЕНЫ ---

try {
    # Читаем файл
    $Content = Get-Content $TargetFile -Raw -Encoding UTF8

    # Ищем, где начинаются правила (rules или rule-providers)
    $Match = [regex]::Match($Content, "(?m)^(rules|rule-providers):")

    if ($Match.Success) {
        # Сохраняем верхнюю часть (прокси, настройки)
        $TopPart = $Content.Substring(0, $Match.Index)
        
        # Приклеиваем новую нижнюю часть
        $FinalContent = $TopPart + $NewBottom
        
        # Перезаписываем файл
        Set-Content -Path $TargetFile -Value $FinalContent -Encoding UTF8
        
        Write-Host "[УСПЕХ] Файл обновлен!" -ForegroundColor Green
        Write-Host "Теперь ПЕРЕЗАГРУЗИТЕ Koala Clash (ПКМ в трее -> Quit, потом запуск)."
    } else {
        Write-Host "ОШИБКА: Не удалось найти секцию 'rules' в файле." -ForegroundColor Red
        Write-Host "Возможно, файл пустой или поврежден."
    }
}
catch {
    Write-Host "КРИТИЧЕСКАЯ ОШИБКА: $_" -ForegroundColor Red
}