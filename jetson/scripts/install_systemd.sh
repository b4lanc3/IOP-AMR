#!/usr/bin/env bash
# install_systemd.sh - Đăng ký service amr-integration để auto-start khi boot.
#
# Cần chạy với sudo.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "[ERR] Cần chạy với sudo: sudo bash scripts/install_systemd.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
UNIT_SRC="$ROOT_DIR/amr_integration/systemd/amr-integration.service"
UNIT_DST="/etc/systemd/system/amr-integration.service"

TARGET_USER="${SUDO_USER:-$USER}"
WS_PATH="${WS_PATH:-/home/$TARGET_USER/robot_ws}"
ROS_DOMAIN_ID_VAL="${ROS_DOMAIN_ID:-0}"

if [[ ! -f "$UNIT_SRC" ]]; then
  echo "[ERR] Không thấy unit file $UNIT_SRC"
  exit 1
fi

if [[ ! -d "$WS_PATH" ]]; then
  echo "[ERR] Workspace $WS_PATH không tồn tại. Đặt biến WS_PATH trước khi chạy:"
  echo "     sudo WS_PATH=/path/to/robot_ws bash scripts/install_systemd.sh"
  exit 1
fi

echo "[1/3] Viết unit file $UNIT_DST (user=$TARGET_USER, ws=$WS_PATH, domain=$ROS_DOMAIN_ID_VAL)"
sed -e "s|{{USER}}|$TARGET_USER|g" \
    -e "s|{{WS_PATH}}|$WS_PATH|g" \
    -e "s|{{ROS_DOMAIN_ID}}|$ROS_DOMAIN_ID_VAL|g" \
    "$UNIT_SRC" > "$UNIT_DST"
chmod 644 "$UNIT_DST"

echo "[2/3] daemon-reload + enable"
systemctl daemon-reload
systemctl enable amr-integration

echo "[3/3] Start"
systemctl start amr-integration
sleep 2
systemctl status amr-integration --no-pager -n 20 || true

echo ""
echo "==============================================="
echo "[OK] Service đăng ký. Quản lý:"
echo "    journalctl -u amr-integration -f"
echo "    sudo systemctl restart amr-integration"
echo "    sudo systemctl disable amr-integration"
echo "==============================================="
