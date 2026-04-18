"""Service /amr/bag/control: start / stop / list rosbag2 ghi từ xa.

Recording bằng subprocess `ros2 bag record` để dùng rosbag2 CLI ổn định.
"""
from __future__ import annotations

import os
import signal
import subprocess
import threading
from pathlib import Path

import rclpy
from rclpy.node import Node

from amr_integration.srv import BagControl


class BaggerNode(Node):
    def __init__(self):
        super().__init__('amr_bagger')
        self.declare_parameter('bag_dir', str(Path.home() / 'bags'))
        bag_dir = Path(str(self.get_parameter('bag_dir').value)).expanduser()
        bag_dir.mkdir(parents=True, exist_ok=True)
        self._bag_dir = bag_dir

        self._proc: subprocess.Popen | None = None
        self._current_name: str | None = None
        self._lock = threading.Lock()

        self.create_service(BagControl, '/amr/bag/control', self._handle)
        self.get_logger().info(f'amr_bagger ready, bag_dir={bag_dir}')

    def _handle(self, req: BagControl.Request, resp: BagControl.Response):
        action = (req.action or '').lower().strip()
        with self._lock:
            if action == 'start':
                self._start(req, resp)
            elif action == 'stop':
                self._stop(resp)
            elif action == 'list':
                self._list(resp)
            else:
                resp.success = False
                resp.message = f'Unknown action: {action}'
        return resp

    def _start(self, req: BagControl.Request, resp: BagControl.Response):
        if self._proc is not None and self._proc.poll() is None:
            resp.success = False
            resp.message = f'Already recording: {self._current_name}'
            return
        name = req.bag_name.strip() or f'bag_{int(rclpy.clock.Clock().now().nanoseconds / 1e9)}'
        topics = [t for t in req.topics if t]
        if not topics:
            topics = ['/scan', '/odom', '/tf', '/tf_static']
        out_path = self._bag_dir / name
        cmd = ['ros2', 'bag', 'record', '-o', str(out_path)] + topics
        self.get_logger().info(f'START: {" ".join(cmd)}')
        self._proc = subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            preexec_fn=os.setsid,
        )
        self._current_name = name
        resp.success = True
        resp.message = f'Recording {name} -> {out_path}'

    def _stop(self, resp: BagControl.Response):
        proc = self._proc
        if proc is None or proc.poll() is not None:
            resp.success = False
            resp.message = 'No recording in progress'
            return
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGINT)
            proc.wait(timeout=8)
        except Exception as exc:
            self.get_logger().warning(f'Graceful stop failed: {exc}')
            try:
                proc.terminate()
            except Exception:
                pass
        self._proc = None
        stopped = self._current_name
        self._current_name = None
        resp.success = True
        resp.message = f'Stopped {stopped}'

    def _list(self, resp: BagControl.Response):
        bags = []
        for p in sorted(self._bag_dir.iterdir()):
            if p.is_dir() and any(p.glob('*.db3')) or any(p.glob('*.mcap')):
                bags.append(p.name)
        resp.success = True
        resp.message = f'{len(bags)} bag(s)'
        resp.bags = bags

    def destroy_node(self):
        if self._proc is not None and self._proc.poll() is None:
            try:
                os.killpg(os.getpgid(self._proc.pid), signal.SIGTERM)
            except Exception:
                pass
        return super().destroy_node()


def main(args=None):
    rclpy.init(args=args)
    node = BaggerNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
