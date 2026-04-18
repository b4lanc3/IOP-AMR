# Build IOP-AMR Control cho Windows: Release + MSIX + ZIP portable.
# Chạy trong PowerShell từ bất kỳ đâu:
#   cd "...\AMR control system\app\scripts"
#   .\build_windows_release.ps1
#
# Yêu cầu: Flutter SDK trên PATH, Visual Studio (C++ desktop), Developer Mode (symlink).

$ErrorActionPreference = "Stop"
$AppDir = Split-Path -Parent $PSScriptRoot
Set-Location $AppDir

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error "flutter không có trên PATH. Thêm ...\flutter\bin vào PATH hoặc mở 'Developer PowerShell'."
}

Write-Host "==> flutter pub get" -ForegroundColor Cyan
flutter pub get

Write-Host "==> flutter build windows --release" -ForegroundColor Cyan
flutter build windows --release

$releaseDir = Join-Path $AppDir "build\windows\x64\runner\Release"
if (-not (Test-Path $releaseDir)) {
  Write-Error "Không thấy $releaseDir"
}

$dist = Join-Path $AppDir "dist"
New-Item -ItemType Directory -Force -Path $dist | Out-Null

# ZIP portable: giải nén là chạy amr_control.exe (cùng các DLL đi kèm).
$verLine = (Get-Content (Join-Path $AppDir "pubspec.yaml") | Select-String '^version:\s*').ToString()
$ver = ($verLine -replace 'version:\s*', '').Trim() -replace '\+.*',''
$zipName = "IOP-AMR-Control-v$ver-win64-portable.zip"
$zipPath = Join-Path $dist $zipName
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Write-Host "==> ZIP portable -> $zipPath" -ForegroundColor Cyan
Compress-Archive -Path (Join-Path $releaseDir '*') -DestinationPath $zipPath -Force

Write-Host "==> dart run msix:create (installer .msix)" -ForegroundColor Cyan
dart run msix:create

Write-Host ""
Write-Host "Xong. Artefacts:" -ForegroundColor Green
Write-Host "  - Portable: $zipPath"
Write-Host "  - MSIX:     $dist\ (tim file *.msix)"
Write-Host "Cài .msix: double-click (có thể cần tin cert test lần đầu)."
