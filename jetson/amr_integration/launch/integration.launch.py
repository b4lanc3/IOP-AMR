"""Launch 3 node phụ trợ: monitor, bagger, estop."""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
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
    ])
