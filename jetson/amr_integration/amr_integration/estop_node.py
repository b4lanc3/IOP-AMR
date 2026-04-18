"""E-stop node.

Khi engaged=True:
  - Liên tục publish `/cmd_vel_estop` với Twist 0 để twist_mux ưu tiên.
  - Service /amr/estop cho phép app bật/tắt.

Ý tưởng: twist_mux config để `/cmd_vel_estop` có priority cao nhất, timeout ngắn.
"""
from __future__ import annotations

import rclpy
from geometry_msgs.msg import Twist
from rclpy.node import Node

from amr_integration.srv import EStop


class EStopNode(Node):
    def __init__(self):
        super().__init__('amr_estop')
        self.declare_parameter('publish_rate_hz', 20.0)
        self.declare_parameter('output_topic', '/cmd_vel_estop')

        self._engaged = False
        self._pub = self.create_publisher(
            Twist, str(self.get_parameter('output_topic').value), 10)
        rate = float(self.get_parameter('publish_rate_hz').value)
        self._timer = self.create_timer(1.0 / max(rate, 1.0), self._tick)
        self.create_service(EStop, '/amr/estop', self._handle)

        self.get_logger().info('amr_estop ready')

    def _handle(self, req: EStop.Request, resp: EStop.Response):
        self._engaged = bool(req.engage)
        resp.success = True
        resp.message = f'E-stop {"ENGAGED" if self._engaged else "RELEASED"}'
        self.get_logger().warning(resp.message)
        return resp

    def _tick(self):
        if not self._engaged:
            return
        msg = Twist()  # zeros by default
        self._pub.publish(msg)


def main(args=None):
    rclpy.init(args=args)
    node = EStopNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
