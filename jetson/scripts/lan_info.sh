#!/usr/bin/env bash
# lan_info.sh - In thông tin cần cho app Flutter kết nối.

set -euo pipefail

echo "========== LAN info cho IOP-AMR =========="
echo "Hostname:   $(hostname)"
echo "mDNS name:  $(hostname).local"
echo ""

echo "### IPv4 addresses"
ip -4 -o addr show scope global | awk '{print "  " $2 ":\t" $4}'
echo ""

ROS_DOMAIN_ID_VAL="${ROS_DOMAIN_ID:-0}"
echo "ROS_DOMAIN_ID: $ROS_DOMAIN_ID_VAL"
echo ""

echo "### Ports sẽ lắng nghe"
echo "  9090/tcp  rosbridge WebSocket"
echo "  8080/tcp  web_video_server (MJPEG)"
echo ""

if command -v ufw >/dev/null 2>&1; then
  echo "### UFW status"
  sudo ufw status 2>/dev/null | sed 's/^/  /' || true
fi

echo ""
echo "### Test từ máy khác trong LAN"
FIRST_IP="$(ip -4 -o addr show scope global | head -1 | awk '{print $4}' | cut -d/ -f1)"
cat <<EOF
  # Ping
  ping $FIRST_IP
  # WebSocket
  wscat -c ws://$FIRST_IP:9090
  # Video
  curl http://$FIRST_IP:8080

Trong app Flutter, thêm robot:
  IP: $FIRST_IP     Port rosbridge: 9090     Port video: 8080
EOF
