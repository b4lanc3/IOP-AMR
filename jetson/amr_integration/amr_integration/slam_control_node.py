"""Service /amr/slam/control — proxy đơn giản sang slam_toolbox.

Hành vi mặc định:
  - 'start'  -> gọi /slam_toolbox/deserialize_pose_graph hoặc khởi động async mode (yêu cầu slam_toolbox đã launch).
  - 'stop'   -> gọi /slam_toolbox/pause_new_measurements.
  - 'save'   -> gọi /slam_toolbox/serialize_map với tên map.
  - 'reset'  -> gọi /slam_toolbox/clear.

Lưu ý: slam_toolbox phải được launch trước; node này không tự khởi động slam_toolbox
mà chỉ điều khiển vòng đời của nó. Nếu chưa launch, start sẽ trả lỗi hướng dẫn.

Để đơn giản trong bản khởi tạo, các nhánh dưới mô phỏng thành công và log cảnh báo
TODO — implement kết nối thực khi đã chốt flow SLAM trên xe.
"""
from __future__ import annotations

import rclpy
from rclpy.node import Node

from amr_integration.srv import SlamControl


class SlamControlNode(Node):
    def __init__(self):
        super().__init__('amr_slam_control')
        self.create_service(SlamControl, '/amr/slam/control', self._handle)
        self.get_logger().info('amr_slam_control ready (proxy stub)')

    def _handle(self, req: SlamControl.Request, resp: SlamControl.Response):
        action = (req.action or '').lower().strip()
        if action not in {'start', 'stop', 'save', 'reset'}:
            resp.success = False
            resp.message = f'Unknown action: {action}'
            return resp

        # TODO: implement real proxy via service clients.
        self.get_logger().warning(
            f'[stub] SLAM {action} requested (map={req.map_name!r}). '
            'Tích hợp với slam_toolbox services ở bước sau.')
        resp.success = True
        resp.message = f'OK (stub): {action}'
        return resp


def main(args=None):
    rclpy.init(args=args)
    node = SlamControlNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
