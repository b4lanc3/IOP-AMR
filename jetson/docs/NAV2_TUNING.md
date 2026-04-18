# Nav2 tuning — SmacPlanner2D (A*) + DWB + Costmap

File template: [`../config/nav2_params.yaml`](../config/nav2_params.yaml).

Copy sang `~/robot_ws/src/<your_nav_pkg>/config/` và reference từ launch.

## Kiến trúc

```
Sensor (LaserScan / PointCloud2)
     │
     ▼
Local Costmap (rolling 3×3m, 0.05m res)     Global Costmap (size=map, 0.05m res)
     │                                             │
     ▼                                             ▼
Controller Server (DWBLocalPlanner)          Planner Server (SmacPlanner2D = A*)
     │                                             │
     └────────── Behavior Tree Navigator ──────────┘
                        │
                        ▼
                    /cmd_vel
```

## 1. Planner server — A*

```yaml
planner_server:
  ros__parameters:
    planner_plugins: ["GridBased"]
    GridBased:
      plugin: "nav2_smac_planner/SmacPlanner2D"
      tolerance: 0.25
      downsample_costmap: false
      use_astar: true         # A*, nếu false dùng Dijkstra
      allow_unknown: true
      max_iterations: 1000000
      max_planning_time: 2.0
      cost_travel_multiplier: 2.0
      smooth_path: true
```

Khi muốn dùng Dijkstra: set `use_astar: false`. Planner alternative:
`nav2_navfn_planner/NavfnPlanner` — đơn giản hơn, nhanh hơn, grid 2D cơ bản.

## 2. Controller server — DWB

```yaml
controller_server:
  ros__parameters:
    controller_frequency: 20.0
    FollowPath:
      plugin: "dwb_core::DWBLocalPlanner"
      max_vel_x: 0.5
      max_vel_theta: 1.2
      acc_lim_x: 1.5
      acc_lim_theta: 2.0
      trans_stopped_velocity: 0.05
      min_x_velocity_threshold: 0.001
      min_theta_velocity_threshold: 0.001
      xy_goal_tolerance: 0.15
      yaw_goal_tolerance: 0.3
      # Critics
      critics: ["RotateToGoal", "Oscillation", "BaseObstacle", "GoalAlign",
                "PathAlign", "PathDist", "GoalDist"]
      BaseObstacle.scale: 0.02
      PathAlign.scale: 32.0
      PathAlign.forward_point_distance: 0.1
      GoalAlign.scale: 24.0
      PathDist.scale: 32.0
      GoalDist.scale: 24.0
```

Troubleshoot DWB:

| Triệu chứng | Sửa |
|---|---|
| Robot dao động trái phải nhiều | Tăng `PathAlign.scale`, giảm `BaseObstacle.scale` |
| Robot né vật cản quá gần | Tăng `inflation_radius` + `BaseObstacle.scale` |
| Robot không rotate đúng lúc tới goal | Tăng `RotateToGoal.scale`, giảm `yaw_goal_tolerance` |
| Không qua được cửa hẹp | Giảm `inflation_radius`, giảm `xy_goal_tolerance` |

## 3. Local costmap

```yaml
local_costmap:
  local_costmap:
    ros__parameters:
      update_frequency: 5.0
      publish_frequency: 2.0
      global_frame: odom
      robot_base_frame: base_link
      rolling_window: true
      width: 3
      height: 3
      resolution: 0.05
      plugins: ["obstacle_layer", "inflation_layer"]
      obstacle_layer:
        plugin: "nav2_costmap_2d::ObstacleLayer"
        observation_sources: scan depth_cloud
        scan:
          topic: /scan
          data_type: "LaserScan"
          max_obstacle_height: 2.0
          clearing: true
          marking: true
        depth_cloud:
          topic: /camera/depth/points
          data_type: "PointCloud2"
          max_obstacle_height: 2.0
          clearing: false
          marking: true
      inflation_layer:
        plugin: "nav2_costmap_2d::InflationLayer"
        inflation_radius: 0.35
        cost_scaling_factor: 3.0
```

## 4. Global costmap

```yaml
global_costmap:
  global_costmap:
    ros__parameters:
      update_frequency: 1.0
      publish_frequency: 1.0
      global_frame: map
      robot_base_frame: base_link
      resolution: 0.05
      track_unknown_space: true
      plugins: ["static_layer", "obstacle_layer", "inflation_layer"]
      static_layer:
        plugin: "nav2_costmap_2d::StaticLayer"
        map_subscribe_transient_local: true
      obstacle_layer:
        plugin: "nav2_costmap_2d::ObstacleLayer"
        observation_sources: scan
        scan:
          topic: /scan
          data_type: "LaserScan"
      inflation_layer:
        plugin: "nav2_costmap_2d::InflationLayer"
        inflation_radius: 0.55
```

## 5. Robot footprint

Với AMR hình chữ nhật 0.6m × 0.45m (điều chỉnh theo thực tế):

```yaml
footprint: "[[0.3, 0.225], [0.3, -0.225], [-0.3, -0.225], [-0.3, 0.225]]"
footprint_padding: 0.02
```

## 6. Twist mux

Ưu tiên e-stop cao nhất để app có thể override mọi nguồn `/cmd_vel`.

```yaml
# config/twist_mux.yaml
topics:
  estop:
    topic: /cmd_vel_estop
    timeout: 0.1
    priority: 100
  teleop:
    topic: /cmd_vel_teleop
    timeout: 0.2
    priority: 50
  nav2:
    topic: /cmd_vel_nav
    timeout: 0.5
    priority: 10
```

Sau đó remap Nav2 controller → `/cmd_vel_nav`, app teleop → `/cmd_vel_teleop`, estop_node spam 0 xuống `/cmd_vel_estop`.

## 7. Tuning workflow từ app

App Flutter (màn Params) gọi `rcl_interfaces/srv/SetParameters` để tune realtime. Các param quan trọng nên expose:

- `controller_server` → `FollowPath.max_vel_x`, `FollowPath.max_vel_theta`.
- `global_costmap/global_costmap` → `inflation_layer.inflation_radius`.
- `local_costmap/local_costmap` → `inflation_layer.inflation_radius`.
- `planner_server` → `GridBased.tolerance`.
