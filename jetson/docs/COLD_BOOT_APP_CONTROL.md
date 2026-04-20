# Cold boot — app điều khiển + systemd (Jetson)

Tài liệu này gom **link GitHub**, hướng dẫn **Cursor (Agent) trên Jetson tự điền placeholder** bằng lệnh thật trên máy, và **Super Prompt** để dán vào Cursor. Không giả định tên package/launch — phải xác minh bằng `ros2 pkg list` / workspace thực tế.

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

## 2. Cursor bên Jetson tự điền placeholder (không đoán)

**Nguyên tắc:** Agent mở workspace `~/IOP-AMR` (hoặc path tương đương), chạy lệnh trên **chính Jetson**, rồi **ghi đầy đủ** bảng dưới trước khi đề xuất `install_systemd.sh`.

| Biến | Cách lấy giá trị (agent tự chạy) |
|------|-----------------------------------|
| `ROBOT_WS_PATH` | Hỏi user hoặc tìm `install/setup.bash` (thường `$HOME/robot_ws`). Xác nhận `test -d "$ROBOT_WS_PATH/install"`. |
| `ROS_DOMAIN_ID` | `echo "${ROS_DOMAIN_ID:-0}"` hoặc đọc từ `/etc/environment`, `~/.bashrc`; mặc định thường `0`. |
| `JETSON_IP` | `hostname -I \| awk '{print $1}'` hoặc `bash ~/IOP-AMR/jetson/scripts/lan_info.sh`. |
| `PKG_MOTOR` + file `.launch.py` | `source /opt/ros/humble/setup.bash && source "$ROBOT_WS_PATH/install/setup.bash" && ros2 pkg list` — chỉ chọn package **có thật** chứa launch motor của robot. |
| `PKG_EXTRA` + file (joy/Flydigi/…) | Cùng bước trên; nếu không có package phù hợp → ghi `EXTRA_DISABLED=1` và **giải thích** (không bịa tên). |
| `MOTOR_LAUNCH_CMD` | Đúng **hai token**: `package ten_file.launch.py` (khớp `install_systemd.sh`). |
| `FLYDIGI_LAUNCH_CMD` | Hai token tương tự; nếu không dùng → phải thống nhất với user cách xử lý unit `amr-extra-launches` (không paste chuỗi giả). |

**Gợi ý mặc định trong script (chỉ là ví dụ README, không thay thế bước xác minh):** `install_systemd.sh` fallback `motor motor_launch.py` và `flydigi Flydigi.launch.py` — chỉ dùng nếu `ros2 pkg list` khớp.

**Sau khi điền**, agent in một khối duy nhất (copy-paste được) rồi mới chạy:

```bash
sudo WS_PATH="..." ROS_DOMAIN_ID="..." \
  MOTOR_LAUNCH_CMD="PKG_MOTOR FILE.launch.py" \
  FLYDIGI_LAUNCH_CMD="PKG_EXTRA FILE.launch.py" \
  bash ~/IOP-AMR/jetson/scripts/install_systemd.sh
```

## 3. Hai kênh điều khiển (nhớ khi debug)

1. **App Flutter:** gamepad trên máy chạy app; lệnh qua **rosbridge**. USB receiver trên Jetson **không** được app đọc.
2. **Receiver trên Jetson:** node ROS (joy / Flydigi / …) + thường **twist_mux**; kiểm tra `/joy`, `/cmd_vel`.

## 4. Super Prompt — dán vào Cursor (Agent) trên Jetson

Copy từ `---BEGIN---` đến `---END---`. Prompt bắt agent **tự chạy lệnh và điền placeholder** — không hardcode tên package.

---BEGIN---

**Vai trò:** Bạn là kỹ sư triển khai ROS2 trên NVIDIA Jetson (Ubuntu 22.04, ROS2 Humble). Nhiệm vụ: robot **tự khởi động sau reboot** và **app IOP-AMR** kết nối được qua LAN; hỗ trợ launch motor + (nếu có) joy/Flydigi trên Jetson.

**Repo:** [https://github.com/b4lanc3/IOP-AMR](https://github.com/b4lanc3/IOP-AMR) — ưu tiên đọc `jetson/docs/PROTOCOL.md` và `jetson/docs/SYSTEMD.md` trước khi sửa file.

**Quy tắc bắt buộc:**

1. **Không** điền `MOTOR_LAUNCH_CMD` / `FLYDIGI_LAUNCH_CMD` bằng tên giả. Phải `source /opt/ros/humble/setup.bash && source <robot_ws>/install/setup.bash` rồi dùng `ros2 pkg list` (và khi cần `ros2 launch <pkg> <file> --show-args` hoặc tìm file trong `src/`) để xác định đúng **package** và **tên file launch**.
2. **Tự điền** `ROBOT_WS_PATH`, `ROS_DOMAIN_ID`, `JETSON_IP` bằng lệnh shell trên Jetson (xem bảng trong `COLD_BOOT_APP_CONTROL.md` mục 2).
3. Trước khi chạy `sudo ... install_systemd.sh`, in ra **bảng placeholder đã điền đủ** để user xác nhận.
4. Nếu thiếu package motor hoặc extra: **dừng**, báo rõ, đề xuất bước tiếp theo — không giả vờ cài được.

**Shell ROS:**

```bash
source /opt/ros/humble/setup.bash
source "$ROBOT_WS_PATH/install/setup.bash"
```

**Checklist:** A) Xác định và ghi `ROBOT_WS_PATH`. B) `install_deps.sh` nếu cần. C) `install_integration.sh "$ROBOT_WS_PATH"`. D) Chạy tay: `full.launch.py`, motor launch, extra launch (nếu có) — kiểm tra topic. E) USB nếu cần. F) Điền biến và chạy `install_systemd.sh`. G) `reboot` + kiểm tra `systemctl` + `journalctl`.

**Khối placeholder — do bạn (agent) điền sau khi chạy lệnh, để trống lúc mới bắt đầu:**

```
ROBOT_WS_PATH=
ROS_DOMAIN_ID=
JETSON_IP=
PKG_MOTOR=
MOTOR_FILE=
PKG_EXTRA=
EXTRA_FILE=
EXTRA_DISABLED=0|1
MOTOR_LAUNCH_CMD="<hai token: package file.launch.py>"
FLYDIGI_LAUNCH_CMD="<hai token hoặc NONE nếu không dùng — khi đó thống nhất user>"
```

---END---

## 5. Xem thêm

- [SYSTEMD.md](SYSTEMD.md) — firewall 9090/8080, restart service.
- [SETUP_JETSON.md](SETUP_JETSON.md) — chạy tay `full.launch.py`.
