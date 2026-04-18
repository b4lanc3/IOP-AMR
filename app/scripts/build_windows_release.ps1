# Build IOP-AMR Control cho Windows (file .exe + DLL) + bản nén + MSIX tùy chọn.
#
# Sau khi chạy, file chạy chính là:
#   dist\IOP-AMR-Control-vX.Y.Z-win64\amr_control.exe
# (phải giữ nguyên cả thư mục — Flutter không gom 1 file .exe đơn lẻ được.)
#
# Chạy:
#   cd "...\AMR control system\app\scripts"
#   .\build_windows_release.ps1
#   .\build_windows_release.ps1 -SkipMsix    # chỉ exe + zip + thư mục dist, không tạo .msix
#
# Yêu cầu: Flutter trên PATH, Visual Studio (C++), Developer Mode (symlink).

param(
  [switch]$SkipMsix
)

$ErrorActionPreference = "Stop"
$AppDir = Split-Path -Parent $PSScriptRoot
Set-Location $AppDir

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error "flutter không có trên PATH."
}

Write-Host "==> flutter pub get" -ForegroundColor Cyan
flutter pub get

Write-Host "==> flutter build windows --release  (sinh ra amr_control.exe)" -ForegroundColor Cyan
flutter build windows --release

$releaseDir = Join-Path $AppDir "build\windows\x64\runner\Release"
$exeBuilt = Join-Path $releaseDir "amr_control.exe"
if (-not (Test-Path $exeBuilt)) {
  Write-Error "Không thấy $exeBuilt — build thất bại."
}

$dist = Join-Path $AppDir "dist"
New-Item -ItemType Directory -Force -Path $dist | Out-Null

$verLine = (Get-Content (Join-Path $AppDir "pubspec.yaml") | Select-String '^version:\s*').ToString()
$ver = ($verLine -replace 'version:\s*', '').Trim() -replace '\+.*', ''

# Thư mục sẵn mang đi máy khác: copy full Release (exe + flutter_windows.dll + data...)
$bundleName = "IOP-AMR-Control-v$ver-win64"
$bundleDir = Join-Path $dist $bundleName
if (Test-Path $bundleDir) {
  Remove-Item $bundleDir -Recurse -Force
}
New-Item -ItemType Directory -Path $bundleDir | Out-Null
Copy-Item -Path (Join-Path $releaseDir '*') -Destination $bundleDir -Recurse -Force

$exeOut = Join-Path $bundleDir "amr_control.exe"
@"
IOP-AMR Control — Windows

Chạy app: double-click file amr_control.exe trong thư mục này.
Không xóa / tách riêng file .exe: cần cùng các file .dll và thư mục data/ ở đây.

Phiên bản: $ver
"@ | Set-Content -Path (Join-Path $bundleDir "README.txt") -Encoding UTF8

Write-Host ""
Write-Host ">>> FILE .EXE (bản phát hành):" -ForegroundColor Green
Write-Host "    $exeOut"
Write-Host ""

# ZIP = nén nguyên thư mục bundle (mang sang máy khác, giải nén rồi chạy .exe).
$zipName = "$bundleName.zip"
$zipPath = Join-Path $dist $zipName
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Write-Host "==> ZIP portable -> $zipPath" -ForegroundColor Cyan
Compress-Archive -Path $bundleDir -DestinationPath $zipPath -Force

if (-not $SkipMsix) {
  Write-Host "==> dart run msix:create (gói .msix — tùy chọn)" -ForegroundColor Cyan
  dart run msix:create --build-windows false
} else {
  Write-Host "==> Bỏ qua MSIX (-SkipMsix)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Xong." -ForegroundColor Green
Write-Host "  - Chạy thử ngay:  & `"$exeOut`""
Write-Host "  - Hoặc mở thư mục: $bundleDir"
Write-Host "  - Gửi máy khác:    $zipPath (giải nén, chạy amr_control.exe)"
if (-not $SkipMsix) {
  Write-Host "  - MSIX (nếu có):   $dist\IOP-AMR-Control-Setup.msix"
}
