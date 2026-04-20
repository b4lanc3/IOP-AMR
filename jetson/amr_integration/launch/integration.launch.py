"""Launch node phụ trợ: monitor, bagger, estop, slam_control, joy_stack."""
import os

from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
    home = os.environ.get('HOME', '/root')
    robot_ws_setup = os.path.join(home, 'robot_ws', 'install', 'setup.bash')

    return LaunchDescription([
        Node(
            package='amr_integration',
            executable='monitor_node',
            name='amr_monitor',
            output='screen',
        ),
        Node(
            package='amr_integration',
            executable='bagger_node',
            name='amr_bagger',
            output='screen',
        ),
        Node(
            package='amr_integration',
            executable='estop_node',
            name='amr_estop',
            output='screen',
        ),
        Node(
            package='amr_integration',
            executable='slam_control_node',
            name='amr_slam_control',
            output='screen',
        ),
        Node(
            package='amr_integration',
            executable='joy_stack_node',
            name='amr_joy_stack',
            output='screen',
            parameters=[{
                'robot_ws_install_setup': robot_ws_setup,
                'launch_package': 'flydigi',
                'launch_file': 'flydigi.launch.py',
            }],
        ),
    ])
