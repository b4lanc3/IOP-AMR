#!/usr/bin/env bash
# install_deps.sh - Cài dependencies hệ thống cho amr_integration trên Jetson.
#
# Usage:  bash scripts/install_deps.sh

set -euo pipefail

if [[ "$(. /etc/os-release && echo "$VERSION_ID")" != "22.04" ]]; then
  echo "[WARN] Script này target Ubuntu 22.04. Bạn đang chạy $(lsb_release -ds)."
fi

if ! command -v ros2 >/dev/null 2>&1; then
  echo "[ERR] ROS2 chưa được source / chưa cài. Cài ROS2 Humble trước."
  exit 1
fi

ROS_DISTRO="${ROS_DISTRO:-humble}"
echo "[INFO] ROS distro: $ROS_DISTRO"

echo "[1/4] apt update"
sudo apt update

echo "[2/4] Cài các package ROS2 cần thiết"
sudo apt install -y \
  ros-"$ROS_DISTRO"-rosbridge-suite \
  ros-"$ROS_DISTRO"-rosapi \
  ros-"$ROS_DISTRO"-web-video-server \
  ros-"$ROS_DISTRO"-rosbag2 \
  ros-"$ROS_DISTRO"-rosbag2-storage-default-plugins \
  ros-"$ROS_DISTRO"-slam-toolbox \
  ros-"$ROS_DISTRO"-navigation2 \
  ros-"$ROS_DISTRO"-nav2-bringup \
  ros-"$ROS_DISTRO"-nav2-smac-planner \
  ros-"$ROS_DISTRO"-twist-mux \
  ros-"$ROS_DISTRO"-rosidl-default-generators \
  ros-"$ROS_DISTRO"-rosidl-default-runtime

echo "[3/4] Cài Python libs (psutil, pyserial, jetson-stats)"
sudo apt install -y python3-psutil python3-serial python3-pip
sudo -H pip3 install --upgrade --no-cache-dir jetson-stats || true

echo "[4/4] UFW: mở port 9090 (rosbridge) + 8080 (web_video_server)"
if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow 9090/tcp || true
  sudo ufw allow 8080/tcp || true
else
  echo "[INFO] ufw chưa cài — bỏ qua bước mở firewall."
fi

echo ""
echo "==============================================="
echo "[OK] Xong. Bước tiếp: chạy scripts/audit_robot_ws.sh ~/robot_ws"
echo "==============================================="
