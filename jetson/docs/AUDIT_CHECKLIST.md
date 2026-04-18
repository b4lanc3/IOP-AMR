# Audit checklist — robot_ws

Dùng khi muốn biết `robot_ws` có sẵn đã đáp ứng PROTOCOL hay chưa. Chạy:

```bash
bash scripts/audit_robot_ws.sh ~/robot_ws
```

Script sẽ tạo `audit-report.txt`. Cross-check với list dưới.

## A. Topic BẮT BUỘC có (robot publish)

| Topic | Tại sao |
|---|---|
| `/scan` (sensor_msgs/LaserScan) | App vẽ 2D + Nav2 |
| `/odom` (nav_msgs/Odometry) | App dashboard + Nav2 |
| `/tf`, `/tf_static` (tf2_msgs/TFMessage) | Frame transforms |
| `/joint_states` (sensor_msgs/JointState) | Vị trí + velocity 2 bánh |
| `/camera/color/image_raw` (sensor_msgs/Image) | Web video stream |
| `/camera/depth/image_raw` (sensor_msgs/Image) | Web video stream |

Nếu tên topic khác, thêm remap trong launch, ví dụ:

```python
Node(package='orbbec_camera', executable='orbbec_camera_node',
     remappings=[('/color/image_raw', '/camera/color/image_raw')])
```

## B. Topic app PUBLISH xuống robot

| Topic | Consumer cần sub |
|---|---|
| `/cmd_vel` → twist_mux → `/cmd_vel_mux/output` → diff_drive_controller |
| `/initialpose` → AMCL |
| `/goal_pose` → Nav2 behavior tree |

## C. Service BẮT BUỘC có

| Service | Node cung cấp |
|---|---|
| `/slam_toolbox/save_map` | slam_toolbox |
| `/<nav2_node>/get_parameters` / `/set_parameters` | các node Nav2 |
| `/amr/estop`, `/amr/bag/control`, `/amr/slam/control` | **amr_integration** (package này sẽ cài) |

## D. Frame TF cần

```
map → odom → base_link → {laser, camera_color, camera_depth, imu}
```

Nếu thiếu frame `map`, phải chạy slam_toolbox hoặc map_server + AMCL.

## E. Khi thiếu gì

| Thiếu | Khắc phục |
|---|---|
| `rosbridge_server` | `bash scripts/install_deps.sh` |
| `web_video_server` | `bash scripts/install_deps.sh` |
| `slam_toolbox` | `sudo apt install ros-humble-slam-toolbox` |
| Nav2 | `sudo apt install ros-humble-navigation2 ros-humble-nav2-bringup ros-humble-nav2-smac-planner` |
| twist_mux | `sudo apt install ros-humble-twist-mux` |
| Topic camera không tồn tại | Kiểm tra OrbbecSDK_ROS2 đã launch chưa |
| Topic `/scan` không có | Kiểm tra `ldlidar_stl_ros2` launch |
| `/tf` không có `map → odom` | Chạy slam_toolbox hoặc AMCL |

## F. Smoke test cuối cùng

```bash
# 1. Dashboard topic
ros2 topic hz /odom                # 20-50 Hz
ros2 topic hz /scan                # 8-12 Hz
ros2 topic hz /camera/color/image_raw  # 15-30 Hz

# 2. Control loop
ros2 topic pub -1 /cmd_vel geometry_msgs/msg/Twist \
  '{linear: {x: 0.1}, angular: {z: 0.0}}'
# Robot phải nhúc nhích, sau đó gửi zero để dừng.

# 3. Bridge
ros2 launch amr_integration bridge.launch.py
# Trên máy khác: wscat -c ws://<jetson-ip>:9090
```
