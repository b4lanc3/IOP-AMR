# Setup integration trên Jetson

Giả định Jetson đã có:

- Ubuntu 22.04 LTS.
- ROS2 Humble đã cài, `source /opt/ros/humble/setup.bash` chạy được.
- `~/robot_ws` đã build & source được; driver LiDAR, camera, motor đã publish topic chuẩn.

## 1. Cài dependencies

```bash
bash scripts/install_deps.sh
```

Script cài:

- `ros-humble-rosbridge-suite` (rosbridge_server, rosapi)
- `ros-humble-web-video-server`
- `ros-humble-rosbag2-*`
- `ros-humble-slam-toolbox` (nếu chưa có)
- `ros-humble-navigation2`, `ros-humble-nav2-bringup`, `ros-humble-nav2-smac-planner`, `ros-humble-twist-mux`
- Python: `psutil`, `pyserial`, `python3-jetson-stats` (tegrastats wrapper)

## 2. Audit robot_ws

```bash
bash scripts/audit_robot_ws.sh ~/robot_ws
```

Script in ra:

- Các topic đang publish.
- Các service đang cung cấp.
- Diff với danh sách yêu cầu trong PROTOCOL.md → cảnh báo thiếu gì.
- Gợi ý các remap cần thêm.

Kết quả ra file `audit-report.txt` trong folder hiện tại.

## 3. Cài amr_integration vào robot_ws

```bash
bash scripts/install_integration.sh ~/robot_ws
```

Script:

1. Copy (hoặc symlink) `amr_integration/` vào `~/robot_ws/src/amr_integration`.
2. `cd ~/robot_ws && colcon build --packages-select amr_integration --symlink-install`.
3. In hướng dẫn `source install/setup.bash`.

## 4. Chạy bridge lần đầu

```bash
source ~/robot_ws/install/setup.bash
ros2 launch amr_integration bridge.launch.py
```

Cùng lúc trên terminal khác, chạy integration nodes:

```bash
ros2 launch amr_integration integration.launch.py
```

Hoặc chạy cả 2 qua file tổng:

```bash
ros2 launch amr_integration full.launch.py
```

## 5. Xác minh

```bash
# Từ Jetson
ros2 topic list | grep amr
ros2 service list | grep amr
curl http://localhost:8080                      # web_video_server

# Từ máy khác LAN
ping <jetson-ip>
wscat -c ws://<jetson-ip>:9090
curl http://<jetson-ip>:8080/stream?topic=/camera/color/image_raw
```

## 6. Auto-start khi Jetson boot

Xem [`SYSTEMD.md`](SYSTEMD.md).

```bash
sudo bash scripts/install_systemd.sh
sudo systemctl status amr-integration
```

## 7. Gỡ cài

```bash
sudo systemctl disable --now amr-integration
sudo rm /etc/systemd/system/amr-integration.service

# Gỡ package
rm -rf ~/robot_ws/src/amr_integration
cd ~/robot_ws && colcon build
```
