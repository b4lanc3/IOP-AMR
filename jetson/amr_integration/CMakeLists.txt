cmake_minimum_required(VERSION 3.8)
project(amr_integration)

if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
endif()

find_package(ament_cmake REQUIRED)
find_package(ament_cmake_python REQUIRED)
find_package(rclpy REQUIRED)
find_package(std_msgs REQUIRED)
find_package(builtin_interfaces REQUIRED)
find_package(rosidl_default_generators REQUIRED)

# Custom interfaces
rosidl_generate_interfaces(${PROJECT_NAME}
  msg/SystemStats.msg
  msg/Battery.msg
  srv/EStop.srv
  srv/BagControl.srv
  srv/SlamControl.srv
  DEPENDENCIES builtin_interfaces std_msgs
)

# Python package
ament_python_install_package(${PROJECT_NAME})

# Entry scripts
install(PROGRAMS
  scripts/monitor_node
  scripts/bagger_node
  scripts/estop_node
  scripts/slam_control_node
  DESTINATION lib/${PROJECT_NAME}
)

# Launch, config
install(DIRECTORY
  launch
  config
  DESTINATION share/${PROJECT_NAME}
)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

ament_export_dependencies(rosidl_default_runtime)
ament_package()
