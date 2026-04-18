"""Publish Jetson system stats + battery state.

Nguồn số liệu ưu tiên:
  - CPU / RAM / temp: psutil + /sys/class/thermal.
  - GPU: jetson-stats (jtop) nếu có, ngược lại 0.
  - Battery: GPIO/ADC nếu có, ngược lại publish mô phỏng để app không chết UI.

Sửa lớp `BatteryReader` khi cắm mạch thật (INA219 / ADC).
"""
from __future__ import annotations

import os
import shutil
import time

import psutil
import rclpy
from rclpy.node import Node

from amr_integration.msg import Battery, SystemStats

try:
    from jtop import jtop  # type: ignore
    HAS_JTOP = True
except Exception:  # pragma: no cover
    HAS_JTOP = False


class BatteryReader:
    """Stub. Thay hàm read() bằng logic đọc INA219 / ADC / CAN tuỳ phần cứng."""

    def read(self) -> dict:
        now = time.time()
        fake_percent = 50.0 + 30.0 * ((now % 60) / 60.0 - 0.5)
        return {
            'voltage': 24.3,
            'current': -1.8,
            'percent': max(0.0, min(100.0, fake_percent)),
            'temperature': 28.5,
            'charging': False,
        }


class MonitorNode(Node):
    def __init__(self):
        super().__init__('amr_monitor')
        self.declare_parameter('stats_rate_hz', 1.0)
        self.declare_parameter('battery_rate_hz', 1.0)
        self.declare_parameter('cpu_thermal_zone', 0)
        self.declare_parameter('gpu_thermal_zone', 1)

        self._stats_pub = self.create_publisher(
            SystemStats, '/amr/system_stats', 10)
        self._battery_pub = self.create_publisher(Battery, '/amr/battery', 10)
        self._battery = BatteryReader()
        self._jtop = jtop() if HAS_JTOP else None
        if self._jtop is not None:
            try:
                self._jtop.start()
            except Exception as exc:  # pragma: no cover
                self.get_logger().warning(f'jtop start failed: {exc}')
                self._jtop = None

        stats_hz = float(self.get_parameter('stats_rate_hz').value)
        batt_hz = float(self.get_parameter('battery_rate_hz').value)
        self.create_timer(1.0 / max(stats_hz, 0.1), self._publish_stats)
        self.create_timer(1.0 / max(batt_hz, 0.1), self._publish_battery)

        self.get_logger().info(
            f'amr_monitor up (stats={stats_hz} Hz, batt={batt_hz} Hz, '
            f'jtop={HAS_JTOP})')

    def _read_temp(self, zone: int) -> float:
        path = f'/sys/class/thermal/thermal_zone{zone}/temp'
        try:
            with open(path, 'r') as fh:
                return float(fh.read().strip()) / 1000.0
        except Exception:
            return 0.0

    def _read_gpu_percent(self) -> float:
        if self._jtop is None:
            return 0.0
        try:
            with self._jtop as jt:
                if jt.ok():
                    return float(jt.stats.get('GPU', 0))
        except Exception:
            return 0.0
        return 0.0

    def _publish_stats(self):
        vm = psutil.virtual_memory()
        usage = shutil.disk_usage('/')
        msg = SystemStats()
        msg.cpu_percent = float(psutil.cpu_percent(interval=None))
        msg.gpu_percent = self._read_gpu_percent()
        msg.ram_used_mb = (vm.total - vm.available) / (1024 ** 2)
        msg.ram_total_mb = vm.total / (1024 ** 2)
        msg.cpu_temp_c = self._read_temp(
            int(self.get_parameter('cpu_thermal_zone').value))
        msg.gpu_temp_c = self._read_temp(
            int(self.get_parameter('gpu_thermal_zone').value))
        msg.disk_used_gb = (usage.total - usage.free) / (1024 ** 3)
        msg.disk_total_gb = usage.total / (1024 ** 3)
        msg.stamp = self.get_clock().now().to_msg()
        self._stats_pub.publish(msg)

    def _publish_battery(self):
        data = self._battery.read()
        msg = Battery()
        msg.voltage = float(data['voltage'])
        msg.current = float(data['current'])
        msg.percent = float(data['percent'])
        msg.temperature = float(data['temperature'])
        msg.charging = bool(data['charging'])
        msg.stamp = self.get_clock().now().to_msg()
        self._battery_pub.publish(msg)

    def destroy_node(self):
        if self._jtop is not None:
            try:
                self._jtop.close()
            except Exception:
                pass
        return super().destroy_node()


def main(args=None):
    rclpy.init(args=args)
    node = MonitorNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
