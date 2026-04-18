# Setup môi trường phát triển trên Windows

Hướng dẫn cài các công cụ để build & chạy Flutter app `app/` trên Windows.

## 1. Yêu cầu hệ thống

- Windows 10/11 64-bit
- ≥ 8 GB RAM (khuyến nghị 16 GB nếu chạy Android emulator)
- ≥ 20 GB trống (Flutter + Android SDK)

## 2. Cài Flutter SDK

Cách 1 — winget (nhanh nhất):

```powershell
winget install --id=Google.Flutter -e
```

Cách 2 — tay:

1. Tải Flutter SDK stable mới nhất: <https://docs.flutter.dev/get-started/install/windows>.
2. Giải nén ra `C:\src\flutter`.
3. Thêm `C:\src\flutter\bin` vào biến môi trường `PATH`.

Kiểm tra:

```powershell
flutter --version
flutter doctor
```

## 3. Cài Android toolchain

1. Tải Android Studio: <https://developer.android.com/studio>.
2. Chạy Android Studio → **More Actions → SDK Manager** → cài:
   - Android SDK Platform 34 (hoặc cao nhất)
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android Emulator
3. Chấp nhận license:

```powershell
flutter doctor --android-licenses
```

4. Tạo emulator (Tools → Device Manager → Create Virtual Device).

## 4. Cài Windows desktop support

Cần Visual Studio 2022 Build Tools với workload **"Desktop development with C++"**.

```powershell
winget install --id=Microsoft.VisualStudio.2022.BuildTools -e
```

Sau đó bật Windows desktop target:

```powershell
flutter config --enable-windows-desktop
flutter config --enable-web
```

## 5. (Tuỳ chọn) VSCode

```powershell
winget install --id=Microsoft.VisualStudioCode -e
```

Extension cần cài:

- Flutter
- Dart
- Error Lens

## 6. Xác nhận cài đặt

```powershell
flutter doctor -v
```

Kỳ vọng 4 mục xanh: Flutter, Android toolchain, Windows (Visual Studio), Chrome (cho web).

## 7. Build & chạy app lần đầu

```powershell
cd app
flutter pub get
flutter run -d windows          # desktop exe
# hoặc
flutter run -d chrome           # PWA
# hoặc
flutter devices                 # liệt kê device
flutter run -d <device-id>      # android thật hoặc emulator
```

## 8. Build release

```powershell
# Android APK
flutter build apk --release
# Output: app/build/app/outputs/flutter-apk/app-release.apk

# Windows exe
flutter build windows --release
# Output: app/build/windows/x64/runner/Release/

# Web (PWA)
flutter build web --release
# Output: app/build/web/
```

## 9. Test không cần Jetson

Khi Jetson tắt, có 2 cách mock:

### a. WSL2 + rosbridge + turtlesim

```bash
# Trong WSL2 Ubuntu 22.04
sudo apt install ros-humble-rosbridge-suite ros-humble-turtlesim
source /opt/ros/humble/setup.bash
ros2 launch rosbridge_server rosbridge_websocket_launch.xml &
ros2 run turtlesim turtlesim_node
```

App kết nối `ws://localhost:9090`, publish `/turtle1/cmd_vel` để test.

### b. Mock server Dart (tạo ở `app/tools/mock_ros_server.dart` sau)

Chạy `dart run tools/mock_ros_server.dart` → giả lập `/scan`, `/map`, `/odom`, `/amr/system_stats`.

## 10. Troubleshooting

Xem [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).
