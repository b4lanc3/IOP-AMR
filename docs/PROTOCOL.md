# Protocol — App ↔ Robot (nguồn chuẩn)

> **Nguồn tin cậy duy nhất** về các topic, service, action, message mà app Flutter và Jetson phải thống nhất.
> `jetson/docs/PROTOCOL.md` là bản sao — đồng bộ bằng `scripts/sync_protocol.ps1`.

## 1. WebSocket & HTTP endpoints

| Endpoint | Port | Giao thức | Mục đích |
|---|---|---|---|
| rosbridge WebSocket | 9090 | ws / wss | JSON roslib protocol |
| web_video_server    | 8080 | HTTP   | MJPEG camera stream |
| rosapi (cùng bridge)| 9090 | ws     | List topic/service động |

URL WebSocket cho app: `ws://<jetson-ip>:9090`
URL camera RGB:       `http://<jetson-ip>:8080/stream?topic=/camera/color/image_raw&type=mjpeg`
URL camera Depth:     `http://<jetson-ip>:8080/stream?topic=/camera/depth/image_raw&type=mjpeg`

## 2. Topic app SUBSCRIBE (robot publish)

| Topic | Msg type | Rate | Mô tả |
|---|---|---|---|
| `/scan` | `sensor_msgs/msg/LaserScan` | ~10 Hz | Hinson LiDAR 2D |
| `/map` | `nav_msgs/msg/OccupancyGrid` | on-change | Map từ slam_toolbox/map_server |
| `/odom` | `nav_msgs/msg/Odometry` | 30–50 Hz | Từ diff_drive_controller |
| `/amcl_pose` | `geometry_msgs/msg/PoseWithCovarianceStamped` | on-change | Khi dùng AMCL |
| `/tf` | `tf2_msgs/msg/TFMessage` | 30–100 Hz | TF động (odom → base_link, map → odom) |
| `/tf_static` | `tf2_msgs/msg/TFMessage` | 1× | TF tĩnh URDF |
| `/joint_states` | `sensor_msgs/msg/JointState` | 30 Hz | Velocity 2 bánh Kinco |
| `/plan` | `nav_msgs/msg/Path` | on-change | Global plan Nav2 |
| `/local_plan` | `nav_msgs/msg/Path` | 10 Hz | Local plan DWB |
| `/amr/system_stats` | `amr_integration/msg/SystemStats` | 1 Hz | CPU/GPU/RAM/temp |
| `/amr/battery` | `amr_integration/msg/Battery` | 1 Hz | Voltage/percent/current |

## 3. Topic app PUBLISH (robot subscribe)

| Topic | Msg type | Rate khi active |
|---|---|---|
| `/cmd_vel` | `geometry_msgs/msg/Twist` | 15 Hz trong teleop |
| `/initialpose` | `geometry_msgs/msg/PoseWithCovarianceStamped` | on-demand |

**Twist format chuẩn**:
```json
{
  "linear":  { "x": 0.3, "y": 0.0, "z": 0.0 },
  "angular": { "x": 0.0, "y": 0.0, "z": 0.5 }
}
```

## 4. Service

| Service | Type | Mục đích |
|---|---|---|
| `/slam_toolbox/save_map` | `slam_toolbox/srv/SaveMap` | Lưu map sau mapping |
| `/amr/slam/control` | `amr_integration/srv/SlamControl` | start / stop / save / reset |
| `/amr/estop` | `amr_integration/srv/EStop` | Engage / release e-stop |
| `/amr/bag/control` | `amr_integration/srv/BagControl` | start / stop / list rosbag |
| `/<node>/get_parameters` | `rcl_interfaces/srv/GetParameters` | Đọc param |
| `/<node>/set_parameters` | `rcl_interfaces/srv/SetParameters` | Tune param live |

## 5. Action

| Action | Type | Mục đích |
|---|---|---|
| `/navigate_to_pose` | `nav2_msgs/action/NavigateToPose` | Click-to-goal |
| `/navigate_through_poses` | `nav2_msgs/action/NavigateThroughPoses` | Waypoint mission |

## 6. Custom messages

### `amr_integration/msg/SystemStats`

```
float32 cpu_percent
float32 gpu_percent
float32 ram_used_mb
float32 ram_total_mb
float32 cpu_temp_c
float32 gpu_temp_c
float32 disk_used_gb
float32 disk_total_gb
builtin_interfaces/Time stamp
```

### `amr_integration/msg/Battery`

```
float32 voltage
float32 current
float32 percent
float32 temperature
bool    charging
builtin_interfaces/Time stamp
```

### `amr_integration/srv/EStop`

```
bool engage        # true = stop, false = release
---
bool success
string message
```

### `amr_integration/srv/BagControl`

```
string action      # "start" | "stop" | "list"
string bag_name
string[] topics
---
bool success
string message
string[] bags
```

### `amr_integration/srv/SlamControl`

```
string action      # "start" | "stop" | "save" | "reset"
string map_name
---
bool success
string message
```

## 7. Namespace multi-robot

Nếu vận hành nhiều robot trên cùng mạng:

- Mỗi Jetson chạy ROS với `ROS_DOMAIN_ID` khác nhau, hoặc
- Cùng DOMAIN_ID nhưng remap namespace: `ros2 launch ... namespace:=robot_1`.

App lưu `namespace` cho từng `RobotProfile` và prefix tất cả topic/service tương ứng.

## 8. Xác thực (optional)

rosbridge mặc định không auth. Với LAN tin cậy có thể bỏ qua. Nếu cần:

- Bật `authenticate: true` trong rosbridge config.
- App gửi service call `/rosauth/authenticate` đầu tiên với `mac` HMAC theo doc [rosauth](https://wiki.ros.org/rosauth).

## 9. Kiểm tra nhanh từ Windows

```powershell
# Install wscat
npm install -g wscat
wscat -c ws://<jetson-ip>:9090

# Subscribe /scan
> {"op":"subscribe","topic":"/scan","type":"sensor_msgs/msg/LaserScan"}

# Publish /cmd_vel (tiến 0.2 m/s)
> {"op":"publish","topic":"/cmd_vel","msg":{"linear":{"x":0.2,"y":0,"z":0},"angular":{"x":0,"y":0,"z":0}}}
```
