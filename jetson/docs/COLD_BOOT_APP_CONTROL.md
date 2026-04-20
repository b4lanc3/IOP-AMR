# Cold boot — app điều khiển + systemd (Jetson)

Tài liệu này gom **link GitHub**, **giá trị placeholder chuẩn cho repo IOP-AMR**, và **Super Prompt** để dán vào Cursor trên Jetson. Cập nhật khi đổi tên package/launch trong `robot_ws`.

## 1. Link GitHub (bookmark)

| Nội dung | URL |
|----------|-----|
| Repo IOP-AMR | [https://github.com/b4lanc3/IOP-AMR](https://github.com/b4lanc3/IOP-AMR) |
| README Jetson | [https://github.com/b4lanc3/IOP-AMR/blob/main/jetson/README.md](https://github.com/b4lanc3/IOP-AMR/blob/main/jetson/README.md) |
| File này (cold boot) | [https://github.com/b4lanc3/IOP-AMR/blob/main/jetson/docs/COLD_BOOT_APP_CONTROL.md](https://github.com/b4lanc3/IOP-AMR/blob/main/jetson/docs/COLD_BOOT_APP_CONTROL.md) |
| PROTOCOL | [https://github.com/b4lanc3/IOP-AMR/blob/main/jetson/docs/PROTOCOL.md](https://github.com/b4lanc3/IOP-AMR/blob/main/jetson/docs/PROTOCOL.md) |
| SYSTEMD | [https://github.com/b4lanc3/IOP-AMR/blob/main/jetson/docs/SYSTEMD.md](https://github.com/b4lanc3/IOP-AMR/blob/main/jetson/docs/SYSTEMD.md) |
| SETUP_JETSON | [https://github.com/b4lanc3/IOP-AMR/blob/main/jetson/docs/SETUP_JETSON.md](https://github.com/b4lanc3/IOP-AMR/blob/main/jetson/docs/SETUP_JETSON.md) |
| `install_systemd.sh` | [https://github.com/b4lanc3/IOP-AMR/blob/main/jetson/scripts/install_systemd.sh](https://github.com/b4lanc3/IOP-AMR/blob/main/jetson/scripts/install_systemd.sh) |

**Clone trên Jetson:**

```bash
git clone https://github.com/b4lanc3/IOP-AMR.git ~/IOP-AMR
```

## 2. Placeholder đã điền (mặc định repo + `install_systemd.sh`)

Các giá trị dưới đây khớp [README](../README.md), [SYSTEMD.md](SYSTEMD.md) và default trong `install_systemd.sh`. Nếu `robot_ws` của bạn dùng tên package/launch khác, chỉnh lại trước khi chạy `install_systemd.sh`.

| Biến | Giá trị điền sẵn | Ghi chú |
|------|------------------|---------|
| `ROBOT_WS_PATH` | `$HOME/robot_ws` | Hoặc path tuyệt đối, ví dụ `/home/ubuntu/robot_ws` |
| `ROS_DOMAIN_ID` | `0` | Đổi nếu nhiều robot trên cùng mạng |
| `JETSON_IP` | *(lấy trên Jetson)* | Chạy: `hostname -I \| awk '{print $1}'` hoặc `bash ~/IOP-AMR/jetson/scripts/lan_info.sh` |
| `PKG_MOTOR` | `motor` | |
| `MOTOR_FILE` | `motor_launch.py` | Hai token systemd: `motor motor_launch.py` |
| `PKG_EXTRA` | `flydigi` | |
| `EXTRA_FILE` | `Flydigi.launch.py` | Hai token systemd: `flydigi Flydigi.launch.py` |
| `EXTRA_DISABLED` | `0` | Đặt `1` nếu không có package Flydigi/joy trên Jetson — khi đó cần cấu hình unit tương ứng (không dùng lệnh giả) |

**Lệnh systemd một dòng (copy sau khi đã `cd ~/IOP-AMR/jetson` và đã build `robot_ws`):**

```bash
sudo WS_PATH="$HOME/robot_ws" ROS_DOMAIN_ID=0 \
  MOTOR_LAUNCH_CMD="motor motor_launch.py" \
  FLYDIGI_LAUNCH_CMD="flydigi Flydigi.launch.py" \
  bash scripts/install_systemd.sh
```

## 3. Hai kênh điều khiển (nhớ khi debug)

1. **App Flutter:** gamepad đọc trên máy chạy app; lệnh qua **rosbridge**. USB receiver cắm Jetson **không** được app đọc.
2. **Receiver trên Jetson:** cần node ROS (joy / Flydigi / …) + thường **twist_mux**; kiểm tra `/joy`, `/cmd_vel` trên robot.

## 4. Super Prompt — dán vào Cursor (Agent) trên Jetson

Copy từ `---BEGIN---` đến `---END---`. Phần `JETSON_IP` đã ghi cách lấy; các giá trị ROS khớp mục 2.

---BEGIN---

**Vai trò:** Bạn là kỹ sư triển khai ROS2 trên NVIDIA Jetson (Ubuntu 22.04, ROS2 Humble). Nhiệm vụ: robot **tự khởi động đầy đủ sau reboot** và **điều khiển được qua app IOP-AMR** trên LAN; hỗ trợ **USB receiver / Flydigi trên Jetson** nếu có trong `robot_ws`.

**Repo:** [https://github.com/b4lanc3/IOP-AMR](https://github.com/b4lanc3/IOP-AMR)

**Giả định:** `/opt/ros/humble/setup.bash`; `~/robot_ws/install/setup.bash`; IOP-AMR tại `~/IOP-AMR`.

**Đọc trước khi sửa:** `~/IOP-AMR/jetson/docs/PROTOCOL.md`, `~/IOP-AMR/jetson/docs/SYSTEMD.md`.

**Mục tiêu sau reboot:** `amr-integration` → `ros2 launch amr_integration full.launch.py`; `amr-extra-launches` → `motor motor_launch.py` và `flydigi Flydigi.launch.py` (đúng format hai token trong `MOTOR_LAUNCH_CMD` / `FLYDIGI_LAUNCH_CMD`).

**Shell ROS:**

```bash
source /opt/ros/humble/setup.bash
source "$HOME/robot_ws/install/setup.bash"
```

**Checklist:** A) `ros2 pkg list` — xác nhận `motor`, `flydigi` (hoặc báo thiếu và dừng). B) `bash ~/IOP-AMR/jetson/scripts/install_deps.sh` nếu chưa. C) `bash ~/IOP-AMR/jetson/scripts/install_integration.sh ~/robot_ws`. D) Ba terminal: `full.launch.py`, motor, Flydigi — kiểm tra topic `cmd_vel`/`joy`/`amr`; từ máy khác `wscat -c ws://JETSON_IP:9090` với `JETSON_IP=$(hostname -I | awk '{print $1}')` chạy trên Jetson. E) USB: `lsusb`, `/dev/input/`. F) Khi D OK:

```bash
cd ~/IOP-AMR/jetson
sudo WS_PATH="$HOME/robot_ws" ROS_DOMAIN_ID=0 \
  MOTOR_LAUNCH_CMD="motor motor_launch.py" \
  FLYDIGI_LAUNCH_CMD="flydigi Flydigi.launch.py" \
  bash scripts/install_systemd.sh
```

G) `sudo reboot` → `systemctl is-active amr-integration amr-extra-launches` → `journalctl -u amr-integration -n 80 --no-pager` và `journalctl -u amr-extra-launches -n 80 --no-pager`.

**Placeholder (đã điền cho workspace chuẩn IOP-AMR — chỉnh nếu robot_ws khác):**

```
ROBOT_WS_PATH=$HOME/robot_ws
ROS_DOMAIN_ID=0
JETSON_IP=<chạy trên Jetson: hostname -I | awk '{print $1}'>
PKG_MOTOR=motor
MOTOR_FILE=motor_launch.py
PKG_EXTRA=flydigi
EXTRA_FILE=Flydigi.launch.py
EXTRA_DISABLED=0
```

---END---

## 5. Xem thêm

- [SYSTEMD.md](SYSTEMD.md) — quản lý service, firewall 9090/8080.
- [SETUP_JETSON.md](SETUP_JETSON.md) — chạy tay `full.launch.py` trước khi bật systemd.
