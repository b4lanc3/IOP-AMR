# Troubleshooting — App Flutter trên Windows

## 1. `flutter doctor` báo lỗi

### Android licenses

```powershell
flutter doctor --android-licenses
```
Chấp nhận tất cả.

### Windows toolchain thiếu

Cần Visual Studio 2022 Build Tools với workload "Desktop development with C++".

```powershell
winget install --id=Microsoft.VisualStudio.2022.BuildTools -e
```

Chạy Visual Studio Installer → Modify → tick workload trên.

## 2. App không kết nối được rosbridge

### Check từ Windows

```powershell
# Ping Jetson
ping <jetson-ip>

# Test WebSocket
npm install -g wscat
wscat -c ws://<jetson-ip>:9090
# Nếu kết nối thành công, gõ lệnh sau và Enter:
{"op":"call_service","service":"/rosapi/topics","id":"test"}
# Phải trả về list topic
```

### Check trên Jetson

```bash
# rosbridge có đang chạy?
ps aux | grep rosbridge
# Listen port 9090?
ss -tlnp | grep 9090
# Firewall có block?
sudo ufw status
sudo ufw allow 9090/tcp
sudo ufw allow 8080/tcp
```

## 3. Camera không hiển thị

- Kiểm tra `web_video_server` chạy: `curl http://<jetson-ip>:8080/` phải trả HTML list topic.
- Kiểm tra topic camera publish: `ros2 topic hz /camera/color/image_raw` (trên Jetson).
- CORS: web build Flutter có thể bị chặn. Launch `web_video_server` với `address:=0.0.0.0` và bật header `Access-Control-Allow-Origin: *` (đã bật mặc định).

## 4. Joystick Flydigi không nhận

- Android: kiểm tra đã pair Bluetooth HID, không phải mode Game (Direwolf có 2 mode — dùng HID).
- Windows: mở `joy.cpl` (Set up USB game controllers) xem Windows có nhận không.
- Check trong app: Settings → Gamepad → tab Events — event stream phải có số khi bấm nút.

## 5. Build APK lỗi Gradle

```powershell
cd app
flutter clean
flutter pub get
cd android
.\gradlew --stop
.\gradlew clean
cd ..
flutter build apk --release
```

## 6. `pub get` chậm / lỗi SSL

Set proxy hoặc mirror cho Pub:

```powershell
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
flutter pub get
```

## 7. Map không render

- Subscribe `/map` — nếu không có data, chưa chạy SLAM hoặc chưa load map_server.
- Kiểm tra `ros2 topic echo /map --once | head -50` trên Jetson.
- App log debug: chạy `flutter run` với flag `--dart-define=LOG_LEVEL=debug`.

## 8. `/cmd_vel` gửi đi nhưng robot không chạy

- `/cmd_vel` có bị twist_mux ghi đè bởi e-stop không? `ros2 topic echo /cmd_vel_mux/output`.
- Motor Kinco enable chưa? Check `ros2 service list | grep enable`.
- Controller spawner đã active? `ros2 control list_controllers` → `diff_drive_controller` phải `active`.
