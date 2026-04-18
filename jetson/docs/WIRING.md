# Wiring reference — Jetson Orin NX + thiết bị ngoại vi

Tham khảo. Thực tế xác nhận lại theo datasheet & pin-out của board carrier đang dùng.

## 1. Cổng USB

| Cổng | Thiết bị đề xuất |
|---|---|
| USB 3.x #1 | Orbbec 3D camera (cần băng thông) |
| USB 3.x #2 | Dự phòng (Flydigi 2.4G dongle nếu test nội bộ) |
| USB 2.0 #1 | Hinson LiDAR (UART-to-USB thường đủ) |
| USB 2.0 #2 | Hub / secondary |

Sau khi cắm LiDAR, kiểm tra:

```bash
ls /dev/ttyUSB*
dmesg | tail -30
```

Nên tạo udev rule cố định symlink:

```bash
# /etc/udev/rules.d/99-hinson-lidar.rules
SUBSYSTEM=="tty", ATTRS{idVendor}=="XXXX", ATTRS{idProduct}=="YYYY", SYMLINK+="hinson_lidar"
```

## 2. Motor Kinco

Kinco hỗ trợ CANopen DS402 hoặc RS485 Modbus. Khuyến nghị CANopen vì:

- Có driver `ros2_canopen` maintained.
- Timing deterministic hơn Modbus.
- Hỗ trợ `ros2_control` → dùng `diff_drive_controller` sẵn.

### CANopen

1. Jetson Orin NX có CAN controller on-SoC — enable DT overlay:
   ```bash
   sudo /opt/nvidia/jetson-io/jetson-io.py
   # Configure Jetson → Configure for compatible hardware → CAN1, CAN2
   sudo reboot
   ```
2. Bring-up CAN interface:
   ```bash
   sudo ip link set can0 type can bitrate 500000
   sudo ip link set can0 up
   ```
3. Cài `ros2_canopen`:
   ```bash
   sudo apt install ros-humble-ros2-canopen ros-humble-ros2-canopen-driver
   ```
4. Tạo config EDS cho Kinco (xin EDS file từ Kinco hoặc tự viết).

### RS485 Modbus (fallback)

Dùng node Python với `pymodbus`:

```python
from pymodbus.client.sync import ModbusSerialClient
client = ModbusSerialClient(method='rtu', port='/dev/ttyUSB_motor', baudrate=115200)
```

Viết custom ros2_control HardwareInterface hoặc node Python publish `/joint_states` + sub `/cmd_vel`.

## 3. Nguồn

- Jetson Orin NX: 12V / 19V DC (kiểm tra carrier board).
- Motor Kinco: theo spec motor (thường 24V/48V DC).
- **Chạy 2 nguồn riêng** hoặc dùng DC/DC step-down đủ công suất. Đất chung (common GND).
- Thêm tụ lọc + fuse đầu Jetson để tránh reset khi motor peak.

## 4. E-stop phần cứng

Khuyến nghị MẠCH e-stop PHẦN CỨNG độc lập phần mềm:

- Nút e-stop cơ (NC) cắt relay nguồn motor driver.
- Thêm pin GPIO Jetson đọc trạng thái nút → gửi về ROS để UI biết.

Phần mềm estop (service `/amr/estop`) CHỈ bổ sung, không thay thế e-stop vật lý.

## 5. Sơ đồ tổng quan

```
                 [Pin / Battery]
                       │
         ┌─────────────┼───────────────┐
         │             │               │
     [DC/DC]       [Fuse]         [Relay cắt]
         │             │               │
     ┌───┴────┐   ┌────┴────┐      ┌───┴────┐
     │ Jetson │   │ Motor HW│      │ E-stop │
     │ Orin NX│   │ driver  │      │  NC sw │
     └───┬────┘   └────┬────┘      └────────┘
         │USB/CAN      │CAN
         ├─Hinson LiDAR│
         ├─Orbbec 3D   │
         └─CAN0 ───────┘
                  motor Kinco L + R
```

## 6. Network

- WiFi nên dùng 5 GHz (AC/AX) hoặc có thể gắn thêm USB-Ethernet kéo dây nếu test ổn định.
- `hostname` Jetson đặt thân thiện (vd `amr-01`) để mDNS discover dễ.
- Set tĩnh IP nếu triển khai production: `sudo nmcli connection modify ...`.
