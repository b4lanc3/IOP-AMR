# Troubleshooting — Jetson side

## 1. rosbridge không chạy

```bash
# Port có bị chiếm?
sudo ss -tlnp | grep 9090

# Install lại
sudo apt install --reinstall ros-humble-rosbridge-suite

# Run tay xem log
source /opt/ros/humble/setup.bash
ros2 launch rosbridge_server rosbridge_websocket_launch.xml port:=9090
```

## 2. `amr_integration` build fail

```bash
cd ~/robot_ws
rm -rf build install log
colcon build --packages-select amr_integration --symlink-install --event-handlers console_direct+
```

Lỗi thường gặp:

| Lỗi | Fix |
|---|---|
| `Could not find rosidl_generate_interfaces` | `sudo apt install ros-humble-rosidl-default-generators ros-humble-rosidl-default-runtime` |
| `ImportError: tegrastats not found` | `sudo pip3 install jetson-stats` rồi `sudo jtop` 1 lần để init |
| `psutil not found` | `sudo apt install python3-psutil` |

## 3. web_video_server trắng

```bash
# Topic image có data?
ros2 topic hz /camera/color/image_raw

# Gõ trực tiếp xem HTML index
curl http://localhost:8080
```

Nếu fps = 0 → driver camera (Orbbec) chưa publish. Reset:

```bash
ros2 node list | grep -i orbbec
ros2 lifecycle set /camera/camera configure
ros2 lifecycle set /camera/camera activate
```

## 4. Nav2 không plan được

- Kiểm tra TF đầy đủ: `ros2 run tf2_tools view_frames` → chú ý `map → odom → base_link`.
- Map đã load: `ros2 topic echo /map --once | head -20`.
- Costmap active: `ros2 lifecycle list` — các node Nav2 phải ở trạng thái `active`.
- Xem log controller: `ros2 topic echo /rosout | grep -i controller`.

## 5. CAN interface không up

```bash
# Check device tree overlay đã apply
sudo dmesg | grep can

# Nếu `can0` không xuất hiện
sudo /opt/nvidia/jetson-io/jetson-io.py
# Bật CAN1/CAN2 → reboot

# Kernel module
sudo modprobe can
sudo modprobe can_raw
sudo modprobe mttcan
```

## 6. Quá nóng

```bash
sudo tegrastats --interval 1000
# CPU_temp > 85°C → giảm freq hoặc thêm fan
sudo /usr/bin/jetson_clocks --show
# Fan control: sudo jetson_clocks --fan
```

## 7. rosbag quá nhiều data

Giới hạn storage mỗi bag:

```bash
ros2 bag record -o myrun --max-bag-size 1073741824 --max-bag-duration 300 \
  /scan /odom /tf /tf_static
```

## 8. WiFi hay rớt

- Dùng `iw dev wlan0 link` kiểm tra RSSI.
- Cân nhắc cắm USB-Ethernet khi test.
- Nếu rớt mỗi lần motor peak current → isolate nguồn Jetson (xem WIRING.md).

## 9. Service amr-integration fail

```bash
journalctl -u amr-integration -n 200 --no-pager
```

Xem [SYSTEMD.md](SYSTEMD.md) mục 5.
