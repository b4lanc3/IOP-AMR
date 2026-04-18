# Gamepad mapping — Flydigi Direwolf

Tay cầm Flydigi Direwolf hoạt động như gamepad HID chuẩn (Xinput trên Windows, Bluetooth HID trên Android).

## Mapping mặc định

| Nút / trục | Key (plugin `gamepads`) | Hành động trong app |
|---|---|---|
| Stick trái — trục Y | `l.y` | `linear.x` (tiến / lùi) |
| Stick phải — trục X | `r.x` | `angular.z` (quay, đảo dấu) |
| A (South) | `button-0` | Toggle e-stop |
| B (East)  | `button-1` | Cycle mode: idle → teleop → auto |
| X (West)  | `button-2` | Snapshot camera |
| Y (North) | `button-3` | Lưu waypoint vào mission đang soạn |
| L1 (LB)   | `button-4` | Giảm max speed 10% |
| R1 (RB)   | `button-5` | Tăng max speed 10% |
| L2 (LT)   | `trigger-l` | Không dùng (reserve) |
| R2 (RT)   | `trigger-r` | Turbo tạm thời (×1.5) |
| Select    | `button-6` | Mở / đóng menu |
| Start     | `button-7` | Quay lại màn Dashboard |
| D-pad     | `dpad-x/y` | Điều hướng UI |
| LSB       | `button-8` | Reset giới hạn speed về mặc định |
| RSB       | `button-9` | Xoay camera view (nếu có gimbal) |

## Cấu hình trong app

Màn **Settings → Gamepad Mapping**:

- Chọn profile: Default / Custom 1 / Custom 2.
- Mỗi nút bấm "Listen" → nhấn nút trên tay cầm → ghi key.
- Trục: chọn inverted (đảo dấu), scale (0.1–2.0), deadzone (0–0.3).
- Lưu vào Hive box `gamepad_profiles`.

## Kết nối tay cầm với app

### Android (điện thoại)
- Bật Bluetooth trên điện thoại.
- Trên Direwolf: giữ nút **Home + Y** 3s vào chế độ Bluetooth HID.
- Pair với điện thoại như thiết bị Bluetooth thường.
- Mở app — plugin `gamepads` nhận event ngay.

### Windows
- Cắm USB-C dock của Direwolf, hoặc dùng dongle 2.4G.
- Windows nhận như Xbox controller.
- App đọc qua plugin `gamepads` (XInput backend).

### iOS
- Flydigi Direwolf không phải MFi certified — iOS 16+ hỗ trợ một số Xbox controller qua Bluetooth, Direwolf có thể không nhận.
- Workaround: dùng joystick ảo trên màn hình.

## Deadzone khuyến nghị

Stick Flydigi có deadzone cơ khí nhỏ, nên set deadzone phần mềm:

- Stick trái (linear): `0.08`
- Stick phải (angular): `0.1`

Scale khuyến nghị:

- Linear: max 0.5 m/s ở trục Y full
- Angular: max 1.2 rad/s ở trục X full
