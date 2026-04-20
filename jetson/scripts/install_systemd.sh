#!/usr/bin/env bash
# install_systemd.sh - Đăng ký service auto-start cho amr-integration + launch bổ sung.
#
# Cần chạy với sudo.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "[ERR] Cần chạy với sudo: sudo bash scripts/install_systemd.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
UNIT_CORE_SRC="$ROOT_DIR/amr_integration/systemd/amr-integration.service"
UNIT_CORE_DST="/etc/systemd/system/amr-integration.service"
UNIT_EXTRA_SRC="$ROOT_DIR/amr_integration/systemd/amr-extra-launches.service"
UNIT_EXTRA_DST="/etc/systemd/system/amr-extra-launches.service"

TARGET_USER="${SUDO_USER:-$USER}"
WS_PATH="${WS_PATH:-/home/$TARGET_USER/robot_ws}"
ROS_DOMAIN_ID_VAL="${ROS_DOMAIN_ID:-0}"
MOTOR_LAUNCH_CMD="${MOTOR_LAUNCH_CMD:-motor motor_launch.py}"
FLYDIGI_LAUNCH_CMD="${FLYDIGI_LAUNCH_CMD:-flydigi Flydigi.launch.py}"

if [[ ! -f "$UNIT_CORE_SRC" ]]; then
  echo "[ERR] Không thấy unit file $UNIT_CORE_SRC"
  exit 1
fi

if [[ ! -f "$UNIT_EXTRA_SRC" ]]; then
  echo "[ERR] Không thấy unit file $UNIT_EXTRA_SRC"
  exit 1
fi

if [[ ! -d "$WS_PATH" ]]; then
  echo "[ERR] Workspace $WS_PATH không tồn tại. Đặt biến WS_PATH trước khi chạy:"
  echo "     sudo WS_PATH=/path/to/robot_ws bash scripts/install_systemd.sh"
  exit 1
fi

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

SED_USER="$(escape_sed "$TARGET_USER")"
SED_WS="$(escape_sed "$WS_PATH")"
SED_DOMAIN="$(escape_sed "$ROS_DOMAIN_ID_VAL")"
SED_MOTOR="$(escape_sed "$MOTOR_LAUNCH_CMD")"
SED_FLYDIGI="$(escape_sed "$FLYDIGI_LAUNCH_CMD")"

echo "[1/4] Viết unit $UNIT_CORE_DST (user=$TARGET_USER, ws=$WS_PATH, domain=$ROS_DOMAIN_ID_VAL)"
sed -e "s|{{USER}}|$SED_USER|g" \
    -e "s|{{WS_PATH}}|$SED_WS|g" \
    -e "s|{{ROS_DOMAIN_ID}}|$SED_DOMAIN|g" \
    "$UNIT_CORE_SRC" > "$UNIT_CORE_DST"
chmod 644 "$UNIT_CORE_DST"

echo "[2/4] Viết unit $UNIT_EXTRA_DST"
sed -e "s|{{USER}}|$SED_USER|g" \
    -e "s|{{WS_PATH}}|$SED_WS|g" \
    -e "s|{{ROS_DOMAIN_ID}}|$SED_DOMAIN|g" \
    -e "s|{{MOTOR_LAUNCH_CMD}}|$SED_MOTOR|g" \
    -e "s|{{FLYDIGI_LAUNCH_CMD}}|$SED_FLYDIGI|g" \
    "$UNIT_EXTRA_SRC" > "$UNIT_EXTRA_DST"
chmod 644 "$UNIT_EXTRA_DST"

echo "[3/4] daemon-reload + enable"
systemctl daemon-reload
systemctl enable amr-integration amr-extra-launches

echo "[4/4] Start services"
systemctl start amr-integration
sleep 1
systemctl start amr-extra-launches
sleep 2
systemctl status amr-integration --no-pager -n 20 || true
systemctl status amr-extra-launches --no-pager -n 20 || true

echo ""
echo "==============================================="
echo "[OK] Services đăng ký. Quản lý:"
echo "    journalctl -u amr-integration -f"
echo "    journalctl -u amr-extra-launches -f"
echo "    sudo systemctl restart amr-integration amr-extra-launches"
echo "    sudo systemctl disable amr-integration amr-extra-launches"
echo ""
echo "Launch command đang dùng:"
echo "    MOTOR_LAUNCH_CMD=\"$MOTOR_LAUNCH_CMD\""
echo "    FLYDIGI_LAUNCH_CMD=\"$FLYDIGI_LAUNCH_CMD\""
echo "==============================================="
