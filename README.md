# IOP-AMR — AMR Control System

> **Hệ thống điều khiển, giám sát và navigation cho robot AMR** qua WiFi/LAN.
> Flutter app chạy trên Windows / Linux / Android / iOS / macOS / Web ↔
> Jetson Orin NX chạy ROS 2 Humble + rosbridge.

<p align="center">
  <a href="#bắt-đầu-nhanh">Bắt đầu nhanh</a> ·
  <a href="#cài-app-cho-người-dùng-cuối">Cài app</a> ·
  <a href="#kết-nối-robot-dde-amr">Kết nối robot</a> ·
  <a href="#kiến-trúc">Kiến trúc</a> ·
  <a href="#phát-triển">Phát triển</a> ·
  <a href="#troubleshooting">Troubleshooting</a>
</p>

---

## 0. Nội dung repo

Monorepo gồm 2 project độc lập:

| Thư mục | Nội dung |
|---|---|
| [`app/`](app/) | **Flutter app** cross-platform (Windows/Linux/Android/iOS/Web/macOS) — controller, monitor, nav UI. |
| [`jetson/`](jetson/) | **ROS 2 integration layer** cho Jetson Orin NX (self-contained — clone/rsync sang Jetson là đủ). |
| [`docs/`](docs/) | Tài liệu cấp repo: protocol, setup Windows/Linux, gamepad mapping, troubleshooting. |
| [`scripts/`](scripts/) | Tool sync cross-platform (sync `docs/PROTOCOL.md` ↔ `jetson/docs/PROTOCOL.md`). |

## 1. Tính năng

### App Flutter (`app/`)
- **Kết nối rosbridge WebSocket v2** — raw WS, có **auto-reconnect** (exponential back‑off), token auth, SSL/WSS tuỳ chọn, namespace multi-robot.
- **mDNS scan** tự tìm Jetson trên LAN; **profile manager** lưu nhiều robot (có preset **DDE-AMR** — Tailscale `100.117.81.58` tạo sẵn ở lần chạy đầu).
- **Dashboard** — hero banner, card pin / vận tốc / pose (odom + AMCL) / system (CPU/GPU/RAM/temp).
- **Teleop** — 2 joystick ảo + tay cầm Flydigi Direwolf (HID), E‑stop, slider giới hạn v/ω, publish `/cmd_vel` 15 Hz.
- **Camera** — MJPEG (RGB + Depth) qua `web_video_server`, snapshot, retry.
- **LiDAR** — vẽ 2D scan real-time (`CustomPainter`), zoom/pan, filter khoảng cách.
- **Map & Nav2** — OccupancyGrid + AMCL pose + tap‑to‑goal gửi `/navigate_to_pose` action.
- **Mapping (SLAM)** — start/stop/save/reset service; live scan overlay.
- **Waypoints** — add pose hiện tại, edit mission, chạy `/navigate_through_poses`.
- **Monitoring** — line chart CPU/GPU/RAM/temp (fl_chart).
- **Params** — tune Nav2 real-time qua `rcl_interfaces/SetParameters`.
- **Logs (rosbag)** — start/stop/list recording, topic picker.
- **Fleet** — grid nhiều robot, đổi robot trực tuyến.
- **Settings** — theme sáng/tối, đơn vị, gamepad mapping editor.
- **UI hiện đại** — Material 3, theme indigo + cyan gradient, StatusDot có pulse, HeroBanner blob gradient, MetricCard với accent gradient.

### Jetson integration (`jetson/`)
- Package ROS 2 `amr_integration` chứa các node phụ trợ:
  - `monitor_node` (CPU/GPU/RAM/temp),
  - `bagger_node` (service ghi rosbag),
  - `estop_node` (service bật/tắt E‑stop + `twist_mux` lock),
  - `system_stats` (tegrastats bridge).
- Launch `bridge.launch.py` dựng sẵn `rosbridge_websocket`, `web_video_server`, `twist_mux`, `amcl`, `nav2_bringup`.
- Script `install_deps.sh`, `audit_robot_ws.sh`, `install_integration.sh`, `install_systemd.sh`.
- Config chuẩn Nav2 (smac A* + DWB) cho diff-drive + Orbbec + Hinson.

## 2. Phần cứng tham chiếu (DDE-AMR)

| Thành phần | Model |
|---|---|
| Compute | NVIDIA **Jetson Orin NX 16 GB** |
| OS / ROS | Ubuntu **22.04 LTS** + ROS 2 **Humble** |
| LiDAR | Hinson 2D |
| Camera 3D | Orbbec (RGB + Depth) |
| Motor | 2× Kinco servo (diff-drive) |
| Controller | Flydigi Direwolf (HID gamepad) |

## 3. Kiến trúc

```
┌───────────────────────────────────────┐          ┌─────────────────────────────────────┐
│ Flutter App                           │          │ Jetson Orin NX — ROS 2 Humble       │
│ Windows / Linux / Android / iOS / Web │          │                                     │
│                                       │          │  robot_ws/ (có sẵn)                 │
│  • rosbridge v2 WebSocket client      │  WiFi /  │  + amr_integration (pkg mới)        │
│  • Flydigi gamepad (HID)              │  LAN /   │    └── rosbridge_server  :9090 ───┐ │
│  • Riverpod state + go_router         │ Tailscale│    └── web_video_server  :8080 ──┐│ │
│  • Hive persistence (profiles)        │          │    └── monitor / bagger / estop  ││ │
└───────────────────────────────────────┘          │    └── twist_mux / amcl / nav2   ││ │
          ▲                                        │                                  ││ │
          │  :9090 WebSocket JSON (rosbridge v2)   │                                  ││ │
          │  :8080 HTTP MJPEG (RGB + Depth)        │                                  ││ │
          └────────────────────────────────────────┴──────────────────────────────────┘│ │
                                                                                        │ │
Giao thức: docs/PROTOCOL.md (bản gốc) ↔ jetson/docs/PROTOCOL.md (đồng bộ qua scripts/)
```

Ba kịch bản mạng:

- **LAN / cùng Wi‑Fi (khuyến nghị cho offline)** — dùng IP `192.168.x.x`.
- **Tailscale** — dùng IP `100.x.x.x`; hoạt động khi cả 2 máy cùng tailnet (direct/DERP).
- **Khác tailnet** — join cùng Tailscale, hoặc VPN khác (WireGuard/ZeroTier), hoặc NAT/port forward rosbridge 9090.

## 4. Bắt đầu nhanh

### 4.1 Trên Jetson (máy robot)
```bash
git clone https://github.com/b4lanc3/IOP-AMR.git ~/IOP-AMR
cd ~/IOP-AMR/jetson
bash scripts/install_deps.sh
bash scripts/audit_robot_ws.sh ~/robot_ws
bash scripts/install_integration.sh ~/robot_ws
# Auto-start khi boot (optional)
sudo bash scripts/install_systemd.sh
```

Kiểm tra rosbridge đã chạy:
```bash
source ~/robot_ws/install/setup.bash
ros2 launch amr_integration bridge.launch.py
# Test từ máy khác:
wscat -c ws://<jetson-ip>:9090
```

Xem thông tin LAN dán vào app:
```bash
bash scripts/lan_info.sh
```

Chi tiết: [`jetson/README.md`](jetson/README.md).

### 4.2 Trên máy điều khiển (app)

| OS | Cách nhanh nhất |
|---|---|
| Windows 10/11 | Tải `IOP-AMR-Control-Setup.msix` (mục 5.1) hoặc build từ source |
| Ubuntu 22.04.5 | Tải `iop-amr-control_1.0.0_amd64.deb` hoặc build từ source |
| Android | Build `flutter build apk --release` rồi cài APK |
| Web / iOS / macOS | Build từ source (xem mục 5) |

## 5. Cài app cho người dùng cuối

### 5.1 Windows

```powershell
cd app
.\scripts\build_windows_release.ps1          # xem script để rõ options
# Output:
#   dist/IOP-AMR-Control-Setup.msix          (installer Windows)
#   dist/IOP-AMR-Control-Windows-x64.zip     (portable)
```

Cài `.msix`: double‑click. Nếu Windows chặn do cert self‑sign → Settings → Developer → bật **App sideloading**.

### 5.2 Linux (Ubuntu 22.04.5)

#### Cách A — build trực tiếp trên Ubuntu
```bash
cd app
chmod +x scripts/build_linux_release.sh
./scripts/build_linux_release.sh --deps      # --deps chỉ cần lần đầu (apt install)
# Output:
#   dist/IOP-AMR-Control-linux-x64.tar.gz
#   dist/iop-amr-control_1.0.0_amd64.deb

# Cài:
sudo dpkg -i dist/iop-amr-control_1.0.0_amd64.deb
# (báo thiếu deps thì)   sudo apt -f install -y
```

Cài one-shot: `./scripts/build_linux_release.sh --install`.

Chi tiết + udev rule cho gamepad + build arm64 (Jetson) trên Linux: [`docs/SETUP_LINUX.md`](docs/SETUP_LINUX.md).

#### Cách B — Docker cross-build từ Windows/macOS

Không có máy Ubuntu sẵn? Build `.deb` bằng Docker Desktop:

```powershell
cd app
docker build -f Dockerfile.linux-build -t iopamr-linux-build .
docker run --rm -v ${PWD}/dist:/out iopamr-linux-build
# File .deb + tar.gz ra thẳng thư mục  app\dist\  trên Windows
```

> `Dockerfile.linux-build` dùng image `ubuntu:22.04` chính hãng + Flutter stable,
> không cần WSL, không cần VM. Sau `docker run` file ra trong `app/dist/`.

### 5.3 Android

```bash
cd app
flutter build apk --release
# APK: app/build/app/outputs/flutter-apk/app-release.apk
adb install -r app/build/app/outputs/flutter-apk/app-release.apk
```

### 5.4 Web (PWA)

```bash
cd app
flutter build web --release
# Output: app/build/web/  — deploy static (nginx, Cloudflare Pages, v.v.)
```

## 6. Kết nối robot (DDE-AMR)

App **tự tạo preset DDE-AMR** (Tailscale `100.117.81.58:9090`, video `8080`) ngay lần chạy đầu nếu chưa có robot nào được lưu.

Các cách kết nối:

| Kịch bản | Host dùng | Ghi chú |
|---|---|---|
| Cùng Wi‑Fi / switch LAN | `192.168.x.x` của Jetson | Ổn nhất, không phụ thuộc Internet. Bật `rosbridge_websocket` listen `0.0.0.0:9090`. |
| Cùng Tailscale | `100.117.81.58` | Preset có sẵn. Phù hợp khi PC ở xa robot. |
| Khác tailnet | (phải tự cấu hình) | Join Tailscale, hoặc VPN khác, hoặc NAT router. |

Trong app: `Connection` → tab **Mạng & robot** để xem gợi ý chi tiết 3 kịch bản; nút **Thêm IP** cho profile mới.

## 7. Phát triển

### 7.1 Setup Windows dev
[`docs/SETUP_WINDOWS.md`](docs/SETUP_WINDOWS.md) — cài Flutter SDK, VS Build Tools, chạy `flutter run -d windows`.

### 7.2 Setup Linux dev
[`docs/SETUP_LINUX.md`](docs/SETUP_LINUX.md) — cài Flutter + GTK deps trên Ubuntu 22.04, build `.deb` / `.tar.gz`, udev gamepad, arm64.

### 7.3 Setup Jetson
[`jetson/docs/SETUP_JETSON.md`](jetson/docs/SETUP_JETSON.md) — cài ROS 2 Humble, nav2 extras, rosbridge.

### 7.4 Protocol (app ↔ robot)
[`docs/PROTOCOL.md`](docs/PROTOCOL.md) — topic / service / action / param schema là **bản gốc**.
Khi sửa, chạy:
```powershell
pwsh scripts/sync_protocol.ps1
```
để đồng bộ sang `jetson/docs/PROTOCOL.md` (và ngược lại nếu sửa bên Jetson).

### 7.5 Cấu trúc Flutter app

```
app/lib/
├── main.dart
├── app.dart                  # MaterialApp + ProviderScope
├── router.dart               # go_router config
├── core/
│   ├── ros/                  # rosbridge v2 client + msg types + topics
│   ├── storage/              # Hive boxes + models (robot/gamepad/settings)
│   ├── discovery/            # mDNS scanner
│   ├── gamepad/              # Flydigi HID mapper
│   ├── providers/            # Riverpod providers
│   └── theme/                # app_theme.dart + ui_kit.dart (BrandMark/StatusDot/HeroBanner/…)
└── features/                 # 12 màn: connection, dashboard, teleop, camera,
                              #          lidar, map, mapping, waypoints,
                              #          monitoring, params, logs, fleet, settings, shell
```

### 7.6 Mock rosbridge (Windows dev)
Nếu chưa có Jetson, chạy mock server trên Windows để smoke test UI:
```powershell
cd app
dart run tool/mock_rosbridge.dart
# Trong app thêm robot host=127.0.0.1 port=9090
```

## 8. Troubleshooting (tóm tắt)

| Hiện tượng | Cách xử lý |
|---|---|
| App không kết nối | Check `ros2 launch amr_integration bridge.launch.py` đang chạy; firewall 9090 |
| MJPEG không hiện | Port 8080; `sudo ufw allow 8080/tcp`; đúng topic ở PROTOCOL |
| Flydigi không nhận | Windows: plug USB dongle, không cần driver. Linux: xem mục [gamepad udev](docs/SETUP_LINUX.md#7-gamepad-flydigi-trên-linux) |
| Tailscale không đi qua | Chạy `tailscale status` 2 bên; check DERP; thử IP LAN nếu cùng phòng |
| Build Windows lỗi `path_provider_foundation` | Đã pin 2.4.1 trong `pubspec.yaml dependency_overrides` |
| Build Linux `Could NOT find GTK` | `sudo apt install libgtk-3-dev pkg-config` |

Chi tiết đầy đủ: [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) · [`jetson/docs/TROUBLESHOOTING.md`](jetson/docs/TROUBLESHOOTING.md).

## 9. License

MIT — xem [`LICENSE`](LICENSE).

## 10. Contributing

- Fork + branch theo convention `feat/...`, `fix/...`, `docs/...`, `refactor/...`.
- Chạy `flutter analyze` trong `app/` không được báo error mới.
- Khi sửa PROTOCOL: dùng `scripts/sync_protocol.ps1` rồi commit cả 2 file.
- Khi thêm màn mới trong app: theo cấu trúc `app/lib/features/<name>/<name>_screen.dart`.
