#!/usr/bin/env bash
# audit_robot_ws.sh - Kiểm kê robot_ws so với PROTOCOL.md.
#
# Usage: bash scripts/audit_robot_ws.sh [WS_PATH]
# Default: ~/robot_ws

set -euo pipefail

WS_PATH="${1:-$HOME/robot_ws}"
REPORT="audit-report.txt"

if [[ ! -d "$WS_PATH" ]]; then
  echo "[ERR] Không tìm thấy workspace: $WS_PATH"
  exit 1
fi

{
  echo "==================================================================="
  echo " AMR robot_ws AUDIT  -  $(date)"
  echo " Workspace: $WS_PATH"
  echo "==================================================================="
  echo ""

  echo "### 1. Packages trong src/"
  ls -1 "$WS_PATH/src" 2>/dev/null || echo "(không có src/)"
  echo ""

  # Source ROS
  if [[ -f "/opt/ros/humble/setup.bash" ]]; then
    # shellcheck disable=SC1091
    source /opt/ros/humble/setup.bash
  fi
  if [[ -f "$WS_PATH/install/setup.bash" ]]; then
    # shellcheck disable=SC1091
    source "$WS_PATH/install/setup.bash"
  else
    echo "[WARN] $WS_PATH/install/setup.bash chưa có. Chạy 'colcon build' trước để audit chính xác."
  fi

  echo "### 2. Topics đang publish"
  timeout 5 ros2 topic list 2>/dev/null | sort || echo "(không lấy được topic list)"
  echo ""

  echo "### 3. Services"
  timeout 5 ros2 service list 2>/dev/null | sort || echo "(không lấy được service list)"
  echo ""

  echo "### 4. Nodes"
  timeout 5 ros2 node list 2>/dev/null | sort || echo "(không lấy được node list)"
  echo ""

  REQUIRED_TOPICS=(
    "/scan" "/odom" "/tf" "/tf_static" "/joint_states"
    "/camera/color/image_raw" "/camera/depth/image_raw"
  )
  echo "### 5. Đối chiếu topic bắt buộc (theo PROTOCOL.md)"
  CURRENT_TOPICS="$(timeout 5 ros2 topic list 2>/dev/null || true)"
  for t in "${REQUIRED_TOPICS[@]}"; do
    if grep -qx "$t" <<<"$CURRENT_TOPICS"; then
      echo "  [OK]       $t"
    else
      echo "  [MISSING]  $t"
    fi
  done
  echo ""

  REQUIRED_PACKAGES=(
    "rosbridge_server" "rosapi" "web_video_server"
    "nav2_bringup" "nav2_smac_planner" "slam_toolbox" "twist_mux"
  )
  echo "### 6. Đối chiếu package hệ thống"
  for p in "${REQUIRED_PACKAGES[@]}"; do
    if ros2 pkg prefix "$p" >/dev/null 2>&1; then
      echo "  [OK]       $p"
    else
      echo "  [MISSING]  $p  → sudo apt install ros-humble-$(echo "$p" | tr '_' '-')"
    fi
  done
  echo ""

  echo "### 7. TF chain"
  timeout 5 ros2 run tf2_ros tf2_echo map base_link --timeout 3 2>&1 | head -20 || true
  echo ""

  echo "==================================================================="
  echo " Hết báo cáo. Đọc tiếp: docs/AUDIT_CHECKLIST.md"
  echo "==================================================================="
} | tee "$REPORT"

echo ""
echo "[INFO] Lưu báo cáo tại: $(pwd)/$REPORT"
