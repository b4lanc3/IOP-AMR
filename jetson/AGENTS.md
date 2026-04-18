# AGENTS — Cursor context cho folder jetson/

> Khi mở Cursor trong folder này, AI sẽ đọc file này trước tiên.

## Mục tiêu của folder

Folder `jetson/` là **integration layer** cho một robot AMR đang chạy Ubuntu 22.04 + ROS2 Humble trên Jetson Orin NX. Folder này có 2 nhiệm vụ:

1. Thêm 1 ROS2 package `amr_integration` vào `~/robot_ws/src/` (đã có sẵn các driver, nav2, slam_toolbox).
2. Cung cấp scripts + docs để cài đặt và vận hành.

Không sửa / không viết lại driver motor Kinco, LiDAR Hinson, hay Orbbec camera — đó là việc của `robot_ws` có sẵn.

## Bối cảnh phần cứng

- Compute: Jetson Orin NX (ARM64).
- OS: Ubuntu 22.04 LTS (JetPack 6 hoặc tương đương).
- ROS: ROS2 Humble Hawksbill.
- LiDAR: Hinson 2D (serial/USB).
- Camera: Orbbec (RGB + Depth).
- Motor: 2× Kinco servo (diff-drive).
- Controller tại thực địa: Flydigi Direwolf (cắm vào điện thoại / PC chạy app Flutter, KHÔNG cắm vào Jetson).

## Nguyên tắc code

1. **PROTOCOL là hợp đồng**: đọc [`docs/PROTOCOL.md`](docs/PROTOCOL.md). Mọi topic / service / action / message type trong code phải khớp.
2. Python nodes dùng `rclpy`, launch file dùng Python launch API.
3. ament_cmake package (vì có msg/srv custom + Python nodes).
4. Tuân thủ ROS2 logging: `self.get_logger().info / warn / error`, không `print`.
5. Parameter phải declare với default, kèm `ParameterDescriptor` mô tả.
6. Service callback KHÔNG block lâu — việc nặng thì đẩy sang executor khác hoặc threading.
7. Tránh monkey-patch; kiểu lifecycle rõ ràng: `__init__` → `start` → `stop` → `destroy_node`.

## Các component trong `amr_integration`

| Node / file | Nhiệm vụ |
|---|---|
| `launch/bridge.launch.py` | Chạy rosbridge_server + rosapi + web_video_server |
| `launch/integration.launch.py` | Chạy monitor_node + bagger_node + estop_node |
| `amr_integration/monitor_node.py` | Parse tegrastats → publish `/amr/system_stats`, đọc battery (ADC/INA219 nếu có) → `/amr/battery` |
| `amr_integration/bagger_node.py` | Service `/amr/bag/control` (start/stop/list rosbag2) |
| `amr_integration/estop_node.py` | Service `/amr/estop` + timer spam `Twist{0,0}` khi engaged |

Custom types (nằm trong `msg/` và `srv/`):

- `msg/SystemStats.msg`
- `msg/Battery.msg`
- `srv/EStop.srv`
- `srv/BagControl.srv`
- `srv/SlamControl.srv` (nếu cần)

## Khi người dùng nhờ sửa/thêm

- **Luôn** đọc PROTOCOL.md trước khi thay đổi bất cứ tên topic / service nào.
- Khi thêm feature mới cần topic/service mới:
  1. Sửa `jetson/docs/PROTOCOL.md` (và đồng bộ lại với `/docs/PROTOCOL.md` ở root — dùng script `scripts/sync_protocol.ps1` trên Windows, hoặc `rsync` tay).
  2. Implement code bên `amr_integration`.
  3. Notify app side (bên Flutter `app/lib/core/ros/topics.dart`).
- Build sau khi sửa:
  ```bash
  cd ~/robot_ws
  colcon build --packages-select amr_integration --symlink-install
  ```

## Không làm gì

- Không bật 3D pointcloud streaming qua rosbridge (quá nặng) — luôn ưu tiên MJPEG từ web_video_server.
- Không run rosbridge WSS self-signed (app Flutter web không trust) trừ khi user yêu cầu tường minh.
- Không tự ý expose service cho phép xoá file trên Jetson qua mạng.
