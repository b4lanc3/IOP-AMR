# Build & chạy IOP-AMR Control trên Ubuntu 22.04.5

Hướng dẫn build app Flutter `app/` thành ứng dụng Linux native
(portable `.tar.gz` + gói `.deb`) trên Ubuntu 22.04 LTS (Jammy).

> Cùng quy trình hoạt động trên **Ubuntu 22.04.x, Pop!_OS 22.04, Linux Mint 21,
> Debian 12** — chỉ khác gói `libayatana-appindicator3-dev` / `libappindicator3-dev`.

## 1. Yêu cầu hệ thống

- Ubuntu 22.04.5 LTS x86_64 (hoặc tương đương — Jetson `arm64` xem mục 6).
- ≥ 6 GB RAM, ≥ 10 GB trống.
- Kết nối mạng để tải Flutter SDK + gói apt.

## 2. Cài Flutter SDK

```bash
# Cách 1 (khuyến nghị): snap
sudo snap install flutter --classic

# Cách 2: tay
cd ~
git clone -b stable https://github.com/flutter/flutter.git
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Kiểm tra:

```bash
flutter --version
flutter doctor -v
```

## 3. Cài system deps (GTK, CMake, build tools)

Script `build_linux_release.sh` có flag `--deps` để cài hộ, nhưng có thể chạy tay:

```bash
sudo apt update
sudo apt install -y \
    clang cmake ninja-build pkg-config \
    libgtk-3-dev libblkid-dev liblzma-dev libstdc++-12-dev \
    mesa-common-dev libglu1-mesa \
    libayatana-appindicator3-dev libsecret-1-dev libunwind-dev \
    fakeroot dpkg-dev
```

Bật Flutter Linux desktop:

```bash
flutter config --enable-linux-desktop
flutter devices   # phải có "Linux (desktop)"
```

## 4. Lấy source + build

```bash
git clone <repo-url> iop-amr
cd iop-amr/app

# lấy dependencies
flutter pub get

# build release (one-shot, có đóng tar.gz + .deb)
chmod +x scripts/build_linux_release.sh
./scripts/build_linux_release.sh --deps      # --deps chỉ cần lần đầu
```

Sau khi build thành công:

- `build/linux/x64/release/bundle/amr_control` — chạy tay ngay được
- `dist/IOP-AMR-Control-linux-x64.tar.gz`    — bundle portable
- `dist/iop-amr-control_1.0.0_amd64.deb`     — gói cài

### Chạy thử (không cần cài)

```bash
./build/linux/x64/release/bundle/amr_control
```

## 4b. Build bằng Docker (không cần máy Linux)

Trên Windows/macOS với **Docker Desktop**:

```powershell
cd app
docker build -f Dockerfile.linux-build -t iopamr-linux-build .
docker run --rm -v ${PWD}/dist:/out iopamr-linux-build
```

File `.deb` + `.tar.gz` xuất ra `app\dist\` trên máy host.

> Image dùng `ubuntu:22.04` + Flutter stable. Lần đầu build mất ~4–6 phút,
> các lần sau nhờ cache chỉ còn bước `flutter build linux --release`.

## 5. Cài `.deb`

```bash
sudo dpkg -i dist/iop-amr-control_1.0.0_amd64.deb
# nếu báo thiếu deps:
sudo apt -f install -y

# hoặc one-shot:
./scripts/build_linux_release.sh --install
```

Ứng dụng xuất hiện trong App Launcher với tên **IOP‑AMR Control**,
binary trong `/opt/iop-amr-control/`, launcher `/usr/bin/iop-amr-control`.

Gỡ:

```bash
sudo apt remove iop-amr-control
```

## 6. Build trên Jetson (arm64 / aarch64)

Flutter SDK không có binary chính thức cho `arm64` Linux trước version 3.22,
nhưng từ Flutter **3.22+** đã có. Cài y như bước 2 (snap hoặc tar) rồi build:

```bash
./scripts/build_linux_release.sh --deps
```

Output sẽ là `arm64` thay vì `amd64`. Nếu script ghi `ARCH=amd64` cứng, đổi
dòng `ARCH="amd64"` trong `scripts/build_linux_release.sh` thành `arm64`
hoặc dùng `dpkg --print-architecture`.

## 7. Gamepad (Flydigi) trên Linux

Plugin `gamepads` đọc `/dev/input/event*`, cần quyền truy cập. Cách đơn giản:

```bash
sudo usermod -aG input $USER
# logout / login lại
```

Cách tốt hơn (tạo udev rule chỉ cho Flydigi):

```bash
sudo tee /etc/udev/rules.d/99-flydigi.rules > /dev/null <<'EOF'
# Flydigi controllers (vendor ID 04b4 / 045e tuỳ model — kiểm tra lsusb)
KERNEL=="event*", SUBSYSTEM=="input", ATTRS{idVendor}=="04b4", MODE="0660", GROUP="input"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Kiểm tra app thấy gamepad:

```bash
evtest   # chọn event# tương ứng, bấm nút -> nên có output
```

## 8. Troubleshooting

| Lỗi | Cách xử lý |
|-----|-----------|
| `Could NOT find GTK` khi cmake | `sudo apt install libgtk-3-dev pkg-config` |
| `libayatana-appindicator3-dev` không tìm thấy | Thay bằng `libappindicator3-dev` (Ubuntu 20.04) |
| App mở không thấy cửa sổ trên Wayland | `GDK_BACKEND=x11 ./amr_control` |
| Lỗi `dart_tool ... permission denied` | `chown -R $USER app/` sau khi build dưới sudo |
| MJPEG camera không hiện | Mở cổng 8080 trên Jetson: `sudo ufw allow 8080/tcp` |
| WebSocket connect timeout | Check `rosbridge_websocket` listen `0.0.0.0:9090` trên Jetson |

## 9. Lưu ý bảo mật mạng

- App kết nối rosbridge qua **WebSocket không mã hoá** mặc định. Nếu qua
  Internet công cộng, bật SSL/WSS ở rosbridge hoặc dùng Tailscale.
- Cổng video 8080 là **MJPEG-stream plain**. Chỉ expose trong LAN / VPN.
