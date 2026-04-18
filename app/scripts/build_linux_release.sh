#!/usr/bin/env bash
# Build script cho Ubuntu 22.04.5 (chạy trực tiếp trên máy Linux).
#
# Ra output:
#   1) dist/IOP-AMR-Control-linux-x64.tar.gz   — bundle portable, giải nén + chạy
#   2) dist/iop-amr-control_1.0.0_amd64.deb    — package .deb dùng dpkg -i
#
# Usage:
#   chmod +x scripts/build_linux_release.sh
#   ./scripts/build_linux_release.sh            # build + đóng gói
#   ./scripts/build_linux_release.sh --install  # build rồi `sudo dpkg -i` luôn
#
set -euo pipefail

APP_NAME="amr_control"
DISPLAY_NAME="IOP-AMR Control"
APP_ID="com.iopamr.amr_control"
VERSION="1.0.0"
ARCH="amd64"
MAINTAINER="IOP-AMR <dev@iopamr.local>"
DESCRIPTION="IOP-AMR Control — cross-platform controller & monitor cho ROS 2 AMR."

# ---------- 1) sanity checks ----------
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$here"

if ! command -v flutter >/dev/null 2>&1; then
  echo "[x] Không thấy 'flutter' trong PATH. Cài Flutter trước (xem docs/SETUP_LINUX.md)."
  exit 1
fi

echo "[i] Flutter: $(flutter --version | head -n 1)"

# ---------- 2) apt deps (tuỳ chọn, bật bằng --deps) ----------
if [[ "${1:-}" == "--deps" || "${1:-}" == "--install" ]]; then
  echo "[i] Cài apt deps cho Ubuntu 22.04..."
  sudo apt-get update
  sudo apt-get install -y \
    clang cmake ninja-build pkg-config \
    libgtk-3-dev libblkid-dev liblzma-dev libstdc++-12-dev \
    mesa-common-dev libglu1-mesa \
    libayatana-appindicator3-dev libsecret-1-dev \
    libunwind-dev \
    fakeroot dpkg-dev
fi

# ---------- 3) flutter deps + build ----------
echo "[i] flutter pub get"
flutter pub get

echo "[i] flutter config --enable-linux-desktop"
flutter config --enable-linux-desktop >/dev/null

echo "[i] flutter build linux --release"
flutter build linux --release

BUNDLE_DIR="build/linux/x64/release/bundle"
if [[ ! -d "$BUNDLE_DIR" ]]; then
  echo "[x] Không thấy $BUNDLE_DIR — build thất bại?"
  exit 1
fi

# ---------- 4) tar.gz portable ----------
mkdir -p dist
tar_name="dist/IOP-AMR-Control-linux-x64.tar.gz"
echo "[i] Đóng tar.gz: $tar_name"
tar -C "$BUNDLE_DIR" -czf "$tar_name" .

# ---------- 5) .deb ----------
pkg_name="iop-amr-control_${VERSION}_${ARCH}"
pkg_root="dist/${pkg_name}"
echo "[i] Chuẩn bị .deb: $pkg_root"
rm -rf "$pkg_root"
mkdir -p "$pkg_root/DEBIAN" \
         "$pkg_root/opt/iop-amr-control" \
         "$pkg_root/usr/bin" \
         "$pkg_root/usr/share/applications" \
         "$pkg_root/usr/share/icons/hicolor/512x512/apps"

# Copy bundle
cp -r "$BUNDLE_DIR"/* "$pkg_root/opt/iop-amr-control/"

# Wrapper trong /usr/bin
cat > "$pkg_root/usr/bin/iop-amr-control" <<EOF
#!/usr/bin/env bash
exec /opt/iop-amr-control/${APP_NAME} "\$@"
EOF
chmod +x "$pkg_root/usr/bin/iop-amr-control"

# .desktop
cat > "$pkg_root/usr/share/applications/${APP_ID}.desktop" <<EOF
[Desktop Entry]
Name=${DISPLAY_NAME}
Comment=${DESCRIPTION}
Exec=/opt/iop-amr-control/${APP_NAME} %U
Icon=${APP_ID}
Terminal=false
Type=Application
Categories=Utility;Development;Network;
StartupWMClass=${APP_ID}
EOF

# Icon (fallback nếu không có assets/icons/app_logo.png)
icon_src="assets/icons/app_logo.png"
icon_dst="$pkg_root/usr/share/icons/hicolor/512x512/apps/${APP_ID}.png"
if [[ -f "$icon_src" ]]; then
  cp "$icon_src" "$icon_dst"
else
  echo "[!] Không có $icon_src — tạo icon rỗng. Nên thêm logo 512x512."
  # 1×1 PNG trong suốt (base64)
  echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mMUkgEAAKoADc8JZJYAAAAASUVORK5CYII=" \
    | base64 -d > "$icon_dst"
fi

# control
installed_size=$(du -sk "$pkg_root" | awk '{print $1}')
cat > "$pkg_root/DEBIAN/control" <<EOF
Package: iop-amr-control
Version: ${VERSION}
Section: net
Priority: optional
Architecture: ${ARCH}
Maintainer: ${MAINTAINER}
Installed-Size: ${installed_size}
Depends: libgtk-3-0, libglib2.0-0, libayatana-appindicator3-1 | libappindicator3-1
Description: ${DESCRIPTION}
 Ứng dụng điều khiển và giám sát AMR qua rosbridge WebSocket.
 Hỗ trợ teleop, camera MJPEG, LiDAR, map/nav2, mapping, fleet.
EOF

echo "[i] dpkg-deb --build"
fakeroot dpkg-deb --build "$pkg_root" "dist/${pkg_name}.deb" >/dev/null
rm -rf "$pkg_root"

echo ""
echo "============================================================"
echo " BUILD DONE"
echo "  tar.gz  : $tar_name"
echo "  deb     : dist/${pkg_name}.deb"
echo "  chạy tay: $BUNDLE_DIR/${APP_NAME}"
echo "  cài deb : sudo dpkg -i dist/${pkg_name}.deb"
echo "  gỡ     : sudo apt remove iop-amr-control"
echo "============================================================"

if [[ "${1:-}" == "--install" ]]; then
  echo "[i] sudo dpkg -i dist/${pkg_name}.deb"
  sudo dpkg -i "dist/${pkg_name}.deb" || sudo apt-get -f install -y
fi
