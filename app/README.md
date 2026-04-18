# IOP-AMR — Flutter App

Cross-platform app điều khiển AMR qua rosbridge WebSocket.

## Setup

Xem [`../docs/SETUP_WINDOWS.md`](../docs/SETUP_WINDOWS.md).

Sau khi cài Flutter SDK:

```powershell
cd app

# Nếu folder android/, ios/, windows/, web/ chưa có (git clone lần đầu):
flutter create . --platforms=android,ios,web,windows,linux,macos --org com.b4lanc3.iopamr

flutter pub get
flutter run -d windows
```

## Cấu trúc

```
lib/
├── main.dart
├── app.dart                       # MaterialApp + ProviderScope
├── router.dart                    # go_router config
├── core/
│   ├── ros/                       # ROS client + msg types + topic constants
│   ├── storage/                   # Hive boxes + models
│   ├── discovery/                 # mDNS scanner
│   ├── gamepad/                   # Flydigi mapping
│   └── theme/                     # Material3 theme
└── features/
    ├── connection/                # Scan & add robots
    ├── dashboard/                 # Overview
    ├── teleop/                    # Joystick + gamepad
    ├── camera/                    # RGB + Depth MJPEG
    ├── lidar/                     # 2D scan view
    ├── map/                       # OccupancyGrid + goal picker
    ├── mapping/                   # SLAM controls
    ├── waypoints/                 # Mission editor
    ├── monitoring/                # CPU/GPU/battery charts
    ├── params/                    # Nav2 param tuning
    ├── logs/                      # rosbag UI
    └── fleet/                     # Multi-robot grid
```

## Build

```powershell
flutter build apk --release          # Android
flutter build windows --release      # Windows exe
flutter build web --release          # PWA
```

### Linux (Ubuntu 22.04.5)

Chi tiết xem [`../docs/SETUP_LINUX.md`](../docs/SETUP_LINUX.md). Tóm tắt:

```bash
cd app
chmod +x scripts/build_linux_release.sh
./scripts/build_linux_release.sh --deps   # lần đầu: cài apt deps + build
# output:
#   dist/IOP-AMR-Control-linux-x64.tar.gz  (portable)
#   dist/iop-amr-control_1.0.0_amd64.deb   (cài: sudo dpkg -i ...)
```
