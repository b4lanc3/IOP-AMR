#!/usr/bin/env bash
# install_integration.sh - Copy amr_integration/ sang robot_ws/src/ và build.
#
# Usage: bash scripts/install_integration.sh [WS_PATH]
# Default: ~/robot_ws

set -euo pipefail

WS_PATH="${1:-$HOME/robot_ws}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PKG_SRC="$ROOT_DIR/amr_integration"
PKG_DST="$WS_PATH/src/amr_integration"

if [[ ! -d "$PKG_SRC" ]]; then
  echo "[ERR] Không thấy $PKG_SRC"
  exit 1
fi
if [[ ! -d "$WS_PATH/src" ]]; then
  echo "[ERR] Workspace src không tồn tại: $WS_PATH/src"
  echo "     Tạo trước: mkdir -p $WS_PATH/src"
  exit 1
fi

echo "[1/3] Copy $PKG_SRC  →  $PKG_DST"
rm -rf "$PKG_DST"
cp -r "$PKG_SRC" "$PKG_DST"

echo "[2/3] Source ROS + build package"
# shellcheck disable=SC1091
source /opt/ros/humble/setup.bash
cd "$WS_PATH"
colcon build --packages-select amr_integration --symlink-install

echo "[3/3] Done"
echo ""
echo "==============================================="
echo "[OK] Package đã build. Để dùng:"
echo "    source $WS_PATH/install/setup.bash"
echo "    ros2 launch amr_integration bridge.launch.py"
echo "==============================================="
