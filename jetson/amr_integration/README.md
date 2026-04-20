# amr_integration — ROS2 package

Package tích hợp để app Flutter ở xa điều khiển robot AMR qua WiFi.

## Nội dung

```
amr_integration/
├── package.xml              ament_cmake + rosidl
├── CMakeLists.txt
├── msg/
│   ├── SystemStats.msg      CPU/GPU/RAM/temp Jetson
│   └── Battery.msg
├── srv/
│   ├── EStop.srv            engage/release
│   ├── BagControl.srv       start/stop/list rosbag2
│   └── SlamControl.srv      start/stop/save/reset slam_toolbox
├── amr_integration/         Python nodes
│   ├── monitor_node.py
│   ├── bagger_node.py
│   └── estop_node.py
├── scripts/                 entry point (chmod +x required)
│   ├── monitor_node
│   ├── bagger_node
│   └── estop_node
├── launch/
│   ├── bridge.launch.py     rosbridge + rosapi + web_video_server
│   ├── integration.launch.py monitor + bagger + estop
│   └── full.launch.py       tất cả
├── config/
│   └── rosbridge.yaml
└── systemd/
    ├── amr-integration.service
    └── amr-extra-launches.service
```

## Build

```bash
# Trong robot_ws
colcon build --packages-select amr_integration --symlink-install
source install/setup.bash
```

## Run

```bash
ros2 launch amr_integration full.launch.py
```

## Custom hoá battery

Mặc định `BatteryReader` trong `monitor_node.py` trả số giả để UI không chết.
Khi có mạch thật (INA219 I2C / ADC / CAN):

```python
class BatteryReader:
    def read(self):
        # Ví dụ INA219
        import board, busio, adafruit_ina219
        i2c = busio.I2C(board.SCL, board.SDA)
        ina = adafruit_ina219.INA219(i2c)
        return {
            'voltage': ina.bus_voltage,
            'current': ina.current / 1000.0,
            'percent': compute_percent(ina.bus_voltage),
            'temperature': 25.0,
            'charging': ina.current > 0,
        }
```

## Topic / service cung cấp

Xem [`../docs/PROTOCOL.md`](../docs/PROTOCOL.md) cho hợp đồng đầy đủ.

- `/amr/system_stats` — `amr_integration/msg/SystemStats` (1 Hz)
- `/amr/battery` — `amr_integration/msg/Battery` (1 Hz)
- `/amr/estop` service — `amr_integration/srv/EStop`
- `/amr/bag/control` service — `amr_integration/srv/BagControl`
- (optional) `/amr/slam/control` service — `amr_integration/srv/SlamControl`
