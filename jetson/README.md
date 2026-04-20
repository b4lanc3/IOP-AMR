# IOP-AMR — Jetson integration

Folder này tự đủ (self-contained). Copy / rsync / clone toàn bộ `jetson/` sang Jetson Orin NX là đủ để cài integration layer vào robot_ws có sẵn.

Trên Jetson m có thể mở Cursor ngay trong folder này để Cursor chỉ scan phần liên quan đến robot (file `.cursorignore` + `AGENTS.md` đã tối ưu context).

## 0. Điều kiện

- Jetson Orin NX chạy **Ubuntu 22.04** + **ROS2 Humble**.
- `robot_ws` có sẵn ở `~/robot_ws` (hoặc path tuỳ chọn) — đã build & source được.
- Mạng LAN kết nối được với máy tính chạy app Flutter.

## 1. Đưa folder sang Jetson

Cách 1 — git clone (khuyến nghị):

```bash
git clone https://github.com/b4lanc3/IOP-AMR ~/IOP-AMR
cd ~/IOP-AMR/jetson
```

Cách 2 — rsync từ Windows (chỉ lấy folder jetson/):

```bash
# Chạy trên Jetson
rsync -avz --progress \
  user@<windows-ip>:/path/to/IOP-AMR/jetson/ \
  ~/amr-jetson/
cd ~/amr-jetson
```

## 2. Cài đặt 4 bước

```bash
# (1) Cài deps hệ thống (rosbridge, web_video_server, nav2 bộ extras...)
bash scripts/install_deps.sh

# (2) Audit robot_ws xem đã có topic/service nào, thiếu gì so với PROTOCOL
bash scripts/audit_robot_ws.sh ~/robot_ws

# (3) Cài package amr_integration vào robot_ws
bash scripts/install_integration.sh ~/robot_ws

# (4) (optional) Auto-start khi boot (amr-integration + motor + Flydigi)
sudo \
  MOTOR_LAUNCH_CMD="motor motor_launch.py" \
  FLYDIGI_LAUNCH_CMD="flydigi Flydigi.launch.py" \
  bash scripts/install_systemd.sh
```

## 3. Chạy thử

```bash
source ~/robot_ws/install/setup.bash
ros2 launch amr_integration bridge.launch.py
```

Từ máy khác test:

```bash
npm install -g wscat
wscat -c ws://<jetson-ip>:9090
```

Xem LAN info cần thiết cho app kết nối:

```bash
bash scripts/lan_info.sh
```

## 4. Layout folder

```
jetson/
├── README.md              ← file này
├── AGENTS.md              ← context cho Cursor bên Jetson
├── .cursorignore          ← giới hạn scope Cursor
├── docs/                  ← đọc theo nhu cầu
│   ├── SETUP_JETSON.md
│   ├── PROTOCOL.md
│   ├── AUDIT_CHECKLIST.md
│   ├── NAV2_TUNING.md
│   ├── SYSTEMD.md
│   ├── WIRING.md
│   └── TROUBLESHOOTING.md
├── scripts/               ← script bash tự động
├── config/                ← template yaml (nav2, twist_mux, auth)
├── launch_refs/           ← launch tham khảo
└── amr_integration/       ← ROS2 package (copy vào ~/robot_ws/src/)
```

## 5. Flow thống nhất với app

Mọi topic / service / action m thấy ở [`docs/PROTOCOL.md`](docs/PROTOCOL.md) là hợp đồng với app Flutter. Nếu robot_ws publish khác tên / namespace → sửa bằng remap trong launch, KHÔNG sửa PROTOCOL.

## 6. Khi sửa code amr_integration

```bash
cd ~/robot_ws
colcon build --packages-select amr_integration --symlink-install
source install/setup.bash
# restart service nếu đã cài systemd:
sudo systemctl restart amr-integration
```
