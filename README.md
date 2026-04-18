# IOP-AMR — AMR Control System

Hệ thống điều khiển robot AMR toàn diện qua WiFi:

- **`app/`** — Flutter app cross-platform (Android / iOS / Web / Windows / Linux / macOS) để điều khiển, giám sát, lập quỹ đạo.
- **`jetson/`** — Folder tự đủ (self-contained) cài integration layer vào robot_ws có sẵn trên Jetson Orin NX (Ubuntu 22.04 + ROS2 Humble).

Phần cứng tham chiếu:

| Thành phần | Cụ thể |
|---|---|
| Compute   | NVIDIA Jetson Orin NX |
| OS        | Ubuntu 22.04 LTS + ROS2 Humble |
| LiDAR     | Hinson 2D |
| Camera 3D | Orbbec (RGB + Depth) |
| Motor     | 2× Kinco servo (diff-drive) |
| Controller| Flydigi Direwolf (HID gamepad) |

## Tính năng

- Teleop bằng joystick ảo + tay cầm Flydigi Direwolf
- Live video camera Orbbec (RGB + Depth) + LiDAR 2D viewer
- SLAM mapping real-time (`slam_toolbox`)
- Navigation A* (`nav2_smac_planner`) + DWB local planner
- Waypoint mission (`/navigate_through_poses`)
- Monitoring: CPU / GPU / RAM / temp / battery
- Tune parameter Nav2 real-time
- Rosbag record / replay từ app
- Multi-robot fleet view

## Kiến trúc

```
┌─────────────────────────────────┐          ┌───────────────────────────────────────┐
│ Flutter App (Windows/Android/…) │          │ Jetson Orin NX — ROS2 Humble          │
│                                 │◀────────▶│                                       │
│  - roslibdart WebSocket client  │  WiFi    │  robot_ws (có sẵn)                    │
│  - Flydigi gamepad              │  :9090   │  + amr_integration (package mới)      │
│  - Map / joystick / video UI    │  :8080   │    - rosbridge_server                 │
└─────────────────────────────────┘          │    - web_video_server                 │
                                             │    - monitor / bagger / estop nodes   │
                                             └───────────────────────────────────────┘
```

## Bắt đầu

- App trên Windows: [`docs/SETUP_WINDOWS.md`](docs/SETUP_WINDOWS.md)
- Jetson: vào folder [`jetson/`](jetson/) và đọc [`jetson/README.md`](jetson/README.md)
- Giao thức app ↔ robot: [`docs/PROTOCOL.md`](docs/PROTOCOL.md)

## Cấu trúc repo

```
.
├── app/            Flutter app (build trên Windows)
├── jetson/         Folder tự đủ, rsync/clone sang Jetson là đủ
├── docs/           Docs cấp repo (PROTOCOL là bản gốc)
├── scripts/        Tool đồng bộ cross-platform (sync_protocol.ps1)
└── README.md
```

## License

MIT — xem [`LICENSE`](LICENSE).
