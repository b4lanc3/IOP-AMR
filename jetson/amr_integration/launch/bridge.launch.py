"""Launch rosbridge_server + rosapi + web_video_server.

Tối thiểu để app Flutter kết nối được.
"""
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    bridge_port = LaunchConfiguration('bridge_port')
    video_port = LaunchConfiguration('video_port')
    address = LaunchConfiguration('address')

    return LaunchDescription([
        DeclareLaunchArgument('bridge_port', default_value='9090'),
        DeclareLaunchArgument('video_port', default_value='8080'),
        DeclareLaunchArgument('address', default_value='0.0.0.0'),

        Node(
            package='rosbridge_server',
            executable='rosbridge_websocket',
            name='rosbridge_websocket',
            output='screen',
            parameters=[{
                'port': bridge_port,
                'address': address,
                'use_compression': False,
                'call_service_timeout': 5.0,
                'send_action_goals_in_new_thread': True,
            }],
        ),
        Node(
            package='rosapi',
            executable='rosapi_node',
            name='rosapi',
            output='screen',
        ),
        Node(
            package='web_video_server',
            executable='web_video_server',
            name='web_video_server',
            output='screen',
            parameters=[{
                'port': video_port,
                'address': address,
                'server_threads': 2,
                'ros_threads': 2,
            }],
        ),
    ])
