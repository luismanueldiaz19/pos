Write-Host "Iniciando compilacion de Flutter para Windows Desktop..." -ForegroundColor Cyan

# 1. Navegar a frontend
Push-Location "$PSScriptRoot\frontend"

Write-Host "Ejecutando flutter clean..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Advertencia al ejecutar flutter clean, continuando..." -ForegroundColor DarkYellow
}

Write-Host "Ejecutando flutter pub get..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al obtener dependencias de Flutter." -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "Compilando Flutter Windows en modo Release..." -ForegroundColor Cyan
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error en la compilacion de Flutter para Windows." -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

# Buscar la ruta del ejecutable generado
$exeX64 = "$PSScriptRoot\frontend\build\windows\x64\runner\Release"
$exeRunner = "$PSScriptRoot\frontend\build\windows\runner\Release"
$outputDir = if (Test-Path $exeX64) { $exeX64 } elseif (Test-Path $exeRunner) { $exeRunner } else { "$PSScriptRoot\frontend\build\windows" }

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  ¡COMPILACION PARA WINDOWS COMPLETADA CON EXITO!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Ejecutable listo en:" -ForegroundColor Cyan
Write-Host "  $outputDir" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green
