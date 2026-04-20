"""Điều khiển tiến trình ros2 launch joy/Flydigi từ app (service /amr/joy_stack)."""
from __future__ import annotations

import os
import signal
import subprocess
import threading
import time

import rclpy
from rclpy.node import Node

from amr_integration.srv import JoyStackControl


class JoyStackNode(Node):
    def __init__(self):
        super().__init__('amr_joy_stack')
        home = os.environ.get('HOME', '/root')
        default_setup = os.path.join(home, 'robot_ws', 'install', 'setup.bash')

        self.declare_parameter('robot_ws_install_setup', default_setup)
        self.declare_parameter('launch_package', 'flydigi')
        self.declare_parameter('launch_file', 'flydigi.launch.py')

        self._lock = threading.Lock()
        self._proc: subprocess.Popen | None = None

        self.create_service(JoyStackControl, '/amr/joy_stack', self._handle)
        self.get_logger().info('amr_joy_stack ready (service /amr/joy_stack)')

    def _install_setup(self) -> str:
        return str(self.get_parameter('robot_ws_install_setup').value)

    def _launch_pkg(self) -> str:
        return str(self.get_parameter('launch_package').value)

    def _launch_file(self) -> str:
        return str(self.get_parameter('launch_file').value)

    def _handle(self, req: JoyStackControl.Request, resp: JoyStackControl.Response):
        setup = self._install_setup()
        if not setup or not os.path.isfile(setup):
            resp.success = False
            resp.message = f'robot_ws_install_setup không hợp lệ: {setup!r}'
            self.get_logger().error(resp.message)
            return resp

        if req.enable:
            return self._start_stack(setup, resp)
        return self._stop_stack(resp)

    def _start_stack(self, setup: str, resp: JoyStackControl.Response):
        with self._lock:
            if self._proc is not None and self._proc.poll() is None:
                resp.success = True
                resp.message = 'Joy stack đã chạy'
                return resp

            pkg = self._launch_pkg()
            launch = self._launch_file()
            inner = (
                f'source /opt/ros/humble/setup.bash && '
                f'source "{setup}" && '
                f'exec ros2 launch {pkg} {launch}'
            )
            try:
                self._proc = subprocess.Popen(
                    ['/bin/bash', '-lc', inner],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    start_new_session=True,
                )
            except OSError as e:
                self._proc = None
                resp.success = False
                resp.message = f'Không spawn được process: {e}'
                self.get_logger().error(resp.message)
                return resp

            time.sleep(0.5)
            if self._proc.poll() is not None:
                code = self._proc.returncode
                self._proc = None
                resp.success = False
                resp.message = f'ros2 launch thoát sớm (exit {code}); kiểm tra package/launch trên robot'
                self.get_logger().error(resp.message)
                return resp

            resp.success = True
            resp.message = f'Đã chạy: ros2 launch {pkg} {launch}'
            self.get_logger().info(resp.message)
            return resp

    def _stop_stack(self, resp: JoyStackControl.Response):
        with self._lock:
            if self._proc is None or self._proc.poll() is not None:
                self._proc = None
                resp.success = True
                resp.message = 'Joy stack không chạy'
                return resp
            try:
                os.killpg(os.getpgid(self._proc.pid), signal.SIGTERM)
            except (ProcessLookupError, PermissionError) as e:
                self.get_logger().warning('killpg: %s', e)
            try:
                self._proc.wait(timeout=8.0)
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(os.getpgid(self._proc.pid), signal.SIGKILL)
                except (ProcessLookupError, PermissionError):
                    pass
            self._proc = None
            resp.success = True
            resp.message = 'Đã dừng joy stack'
            self.get_logger().info(resp.message)
            return resp


def main(args=None):
    rclpy.init(args=args)
    node = JoyStackNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
