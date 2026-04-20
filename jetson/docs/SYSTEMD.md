# systemd — auto-start khi Jetson boot

Mục tiêu: Jetson vừa boot xong là app Flutter ở xa đã kết nối được, và các launch quan trọng tự bật:

- `amr-integration.service`: rosbridge + web_video + monitor + estop + bagger.
- `amr-extra-launches.service`: auto chạy 2 launch bổ sung (motor + Flydigi).

## 1. Cài unit

Chỉ cần chạy 1 lần:

```bash
sudo bash scripts/install_systemd.sh
```

Hoặc chỉ định rõ launch command (khuyến nghị):

```bash
sudo \
  WS_PATH=/home/$USER/robot_ws \
  MOTOR_LAUNCH_CMD="motor motor_launch.py" \
  FLYDIGI_LAUNCH_CMD="flydigi Flydigi.launch.py" \
  bash scripts/install_systemd.sh
```

Script sẽ:

1. Copy `amr_integration/systemd/amr-integration.service` → `/etc/systemd/system/`.
2. Copy `amr_integration/systemd/amr-extra-launches.service` → `/etc/systemd/system/`.
3. Thay placeholder `{{USER}}`, `{{WS_PATH}}`, `{{ROS_DOMAIN_ID}}`, launch command.
4. `systemctl daemon-reload` + enable/start cả 2 service.

## 2. Thao tác

```bash
# Khởi động
sudo systemctl start amr-integration

# Trạng thái
systemctl status amr-integration

# Xem log real-time
journalctl -u amr-integration -f

# Tắt tạm
sudo systemctl stop amr-integration

# Tắt hẳn (không auto-start lần boot sau)
sudo systemctl disable amr-integration

# Restart sau khi sửa code/rebuild
sudo systemctl restart amr-integration

# Restart phần motor + Flydigi
sudo systemctl restart amr-extra-launches
```

## 3. Unit file

Xem:

- [`../amr_integration/systemd/amr-integration.service`](../amr_integration/systemd/amr-integration.service)
- [`../amr_integration/systemd/amr-extra-launches.service`](../amr_integration/systemd/amr-extra-launches.service)

Điểm quan trọng:

- `User=` phải khớp user chạy ROS.
- `Environment="ROS_DOMAIN_ID=0"` — thay bằng DOMAIN_ID thực tế nếu multi-robot.
- `ExecStart=` dùng wrapper shell source ROS + workspace rồi mới launch.
- `Restart=on-failure` + `RestartSec=5` để auto-recover.
- Service extra dùng `ros2 launch ... & ros2 launch ... & wait -n` để quản lý 2 launch trong 1 unit.

## 4. Lưu ý bảo mật

- Service chạy dưới user thường (không root) — tốt cho an toàn hệ thống.
- Mở port rosbridge 9090 và web_video 8080 trên firewall LAN:
  ```bash
  sudo ufw allow 9090/tcp
  sudo ufw allow 8080/tcp
  ```
- Nếu muốn public internet: đặt sau VPN (Tailscale / WireGuard), KHÔNG port-forward thẳng.

## 5. Debug khi service fail

```bash
journalctl -u amr-integration -n 200 --no-pager
journalctl -u amr-extra-launches -n 200 --no-pager
```

Lỗi thường gặp:

| Log | Khắc phục |
|---|---|
| `source: command not found` | Unit dùng `/bin/sh` → đổi sang `/bin/bash -lc '...'` |
| `setup.bash: No such file` | Workspace chưa build; chạy `colcon build` rồi restart |
| `Could not find package 'amr_integration'` | Chưa cài qua `install_integration.sh` |
| Port 9090 đã bị dùng | Kill tiến trình rosbridge cũ: `pkill -f rosbridge` |
