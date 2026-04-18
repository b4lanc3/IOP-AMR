"""Launch tham khảo gộp: bridge + integration + (optional) Nav2 bringup.

Không phải package chính — chỉ để copy/tham khảo vào launch của robot_ws.
"""
import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    pkg_integration = get_package_share_directory('amr_integration')

    use_nav2 = LaunchConfiguration('use_nav2')
    map_yaml = LaunchConfiguration('map')

    declare_use_nav2 = DeclareLaunchArgument(
        'use_nav2', default_value='false',
        description='Có include Nav2 bringup hay không.',
    )
    declare_map = DeclareLaunchArgument(
        'map', default_value='',
        description='Đường dẫn đến <name>.yaml nếu chạy Nav2 với map tĩnh.',
    )

    bridge = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(pkg_integration, 'launch', 'bridge.launch.py')),
    )
    integration = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(pkg_integration, 'launch', 'integration.launch.py')),
    )

    # Twist mux (nếu đã cài)
    twist_mux = Node(
        package='twist_mux',
        executable='twist_mux',
        name='twist_mux',
        output='screen',
        parameters=[os.path.join(pkg_integration, 'config', 'twist_mux.yaml')],
    )

    nav2 = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(
                get_package_share_directory('nav2_bringup'),
                'launch', 'bringup_launch.py'),
        ),
        launch_arguments={
            'map': map_yaml,
            'use_sim_time': 'false',
            'params_file': os.path.join(pkg_integration, 'config', 'nav2_params.yaml'),
        }.items(),
        condition=None,  # gắn điều kiện use_nav2 ở phía bên ngoài nếu cần
    )

    return LaunchDescription([
        declare_use_nav2,
        declare_map,
        bridge,
        integration,
        twist_mux,
        # nav2,  # uncomment khi sẵn sàng
    ])
