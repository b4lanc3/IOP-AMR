// Mock rosbridge v2 server dùng để smoke-test UI khi chưa có Jetson thật.
// Chạy: `dart run tool/mock_rosbridge.dart` trong thư mục `app/`.
//
// Mặc định lắng nghe ws://0.0.0.0:9090 — giống rosbridge_websocket.
// Publish các topic "giả": /amr/battery, /amr/system_stats, /odom, /scan,
// /amcl_pose, /plan, và phản hồi service /amr/estop, /amr/slam/control,
// /amr/bag/control, /slam_toolbox/save_map.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

const _port = 9090;

void main(List<String> args) async {
  final port =
      args.isNotEmpty ? int.tryParse(args.first) ?? _port : _port;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln(
      '[mock-rosbridge] Listening on ws://${server.address.host}:$port');
  stdout.writeln(
      '  Ctrl+C để thoát. Bật app, nhập host=localhost port=$port.');

  await for (final req in server) {
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      final ws = await WebSocketTransformer.upgrade(req);
      final client = _MockClient(ws);
      client.start();
    } else {
      req.response
        ..statusCode = HttpStatus.ok
        ..write('mock rosbridge up')
        ..close();
    }
  }
}

class _MockClient {
  _MockClient(this.socket);
  final WebSocket socket;

  final _subs = <String, _Sub>{};
  Timer? _batteryTimer;
  Timer? _statsTimer;
  Timer? _odomTimer;
  Timer? _scanTimer;
  Timer? _poseTimer;
  Timer? _planTimer;
  final _rnd = math.Random();
  int _t = 0;

  void start() {
    stdout.writeln('[mock-rosbridge] client connected');
    socket.listen(_onMessage, onDone: _cleanup, onError: (_) => _cleanup());
  }

  void _cleanup() {
    stdout.writeln('[mock-rosbridge] client disconnected');
    _batteryTimer?.cancel();
    _statsTimer?.cancel();
    _odomTimer?.cancel();
    _scanTimer?.cancel();
    _poseTimer?.cancel();
    _planTimer?.cancel();
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final msg = jsonDecode(raw) as Map<String, dynamic>;
      final op = msg['op'] as String?;
      switch (op) {
        case 'subscribe':
          _onSubscribe(msg);
          break;
        case 'unsubscribe':
          _onUnsubscribe(msg);
          break;
        case 'advertise':
          // accept silently
          break;
        case 'unadvertise':
          break;
        case 'publish':
          // echo /cmd_vel for debug
          final t = msg['topic'];
          if (t == '/cmd_vel' || (t is String && t.endsWith('/cmd_vel'))) {
            final m = msg['msg'] as Map<String, dynamic>;
            final lx = (m['linear']?['x'] as num?)?.toDouble() ?? 0;
            final az = (m['angular']?['z'] as num?)?.toDouble() ?? 0;
            stdout.writeln(
                '[cmd_vel] lin=${lx.toStringAsFixed(2)} ang=${az.toStringAsFixed(2)}');
          }
          break;
        case 'call_service':
          _onService(msg);
          break;
        case 'send_action_goal':
          _onActionGoal(msg);
          break;
        default:
          stdout.writeln('[mock-rosbridge] unknown op: $op');
      }
    } catch (e) {
      stdout.writeln('[mock-rosbridge] parse error: $e');
    }
  }

  void _onSubscribe(Map<String, dynamic> m) {
    final topic = m['topic'] as String;
    final id = (m['id'] as String?) ?? 'sub_${_rnd.nextInt(1 << 30)}';
    _subs[topic] = _Sub(id, topic);
    _startFeedsFor(topic);
  }

  void _onUnsubscribe(Map<String, dynamic> m) {
    _subs.remove(m['topic'] as String);
  }

  void _startFeedsFor(String topic) {
    if (topic.endsWith('/amr/battery') && _batteryTimer == null) {
      _batteryTimer = Timer.periodic(
          const Duration(seconds: 1), (_) => _publishBattery(topic));
    }
    if (topic.endsWith('/amr/system_stats') && _statsTimer == null) {
      _statsTimer = Timer.periodic(
          const Duration(seconds: 1), (_) => _publishStats(topic));
    }
    if (topic == '/odom' && _odomTimer == null) {
      _odomTimer = Timer.periodic(
          const Duration(milliseconds: 200), (_) => _publishOdom(topic));
    }
    if (topic == '/scan' && _scanTimer == null) {
      _scanTimer = Timer.periodic(
          const Duration(milliseconds: 200), (_) => _publishScan(topic));
    }
    if (topic == '/amcl_pose' && _poseTimer == null) {
      _poseTimer = Timer.periodic(
          const Duration(milliseconds: 500), (_) => _publishAmclPose(topic));
    }
    if (topic == '/plan' && _planTimer == null) {
      _planTimer = Timer.periodic(
          const Duration(seconds: 1), (_) => _publishPlan(topic));
    }
  }

  void _send(Map<String, dynamic> msg) {
    if (socket.readyState != WebSocket.open) return;
    socket.add(jsonEncode(msg));
  }

  void _publish(String topic, String type, Map<String, dynamic> data) {
    _send({'op': 'publish', 'topic': topic, 'type': type, 'msg': data});
  }

  void _publishBattery(String topic) {
    _t++;
    final pct = 95 - (_t % 300) * 0.2;
    _publish(topic, 'amr_integration/msg/Battery', {
      'voltage': 24 + (_rnd.nextDouble() - 0.5),
      'current': 2.5 + (_rnd.nextDouble() - 0.5) * 0.5,
      'percent': pct.clamp(0, 100),
      'temperature': 32 + _rnd.nextDouble() * 2,
      'charging': false,
    });
  }

  void _publishStats(String topic) {
    _publish(topic, 'amr_integration/msg/SystemStats', {
      'cpu_percent': 25 + _rnd.nextDouble() * 40,
      'gpu_percent': 15 + _rnd.nextDouble() * 30,
      'ram_used_mb': 3000 + _rnd.nextDouble() * 1000,
      'ram_total_mb': 8000,
      'cpu_temp_c': 55 + _rnd.nextDouble() * 10,
      'gpu_temp_c': 50 + _rnd.nextDouble() * 15,
      'disk_used_gb': 45,
      'disk_total_gb': 128,
    });
  }

  double _odomX = 0;
  double _odomY = 0;
  double _odomYaw = 0;

  void _publishOdom(String topic) {
    _odomX += math.cos(_odomYaw) * 0.01;
    _odomY += math.sin(_odomYaw) * 0.01;
    _odomYaw += 0.005;
    final half = _odomYaw / 2;
    _publish(topic, 'nav_msgs/msg/Odometry', {
      'header': _header('odom'),
      'child_frame_id': 'base_link',
      'pose': {
        'pose': {
          'position': {'x': _odomX, 'y': _odomY, 'z': 0.0},
          'orientation': {
            'x': 0.0,
            'y': 0.0,
            'z': math.sin(half),
            'w': math.cos(half),
          },
        },
        'covariance': List.filled(36, 0.0),
      },
      'twist': {
        'twist': {
          'linear': {'x': 0.3 + _rnd.nextDouble() * 0.1, 'y': 0.0, 'z': 0.0},
          'angular': {'x': 0.0, 'y': 0.0, 'z': 0.2},
        },
        'covariance': List.filled(36, 0.0),
      },
    });
  }

  void _publishScan(String topic) {
    const n = 360;
    final ranges = List<double>.generate(n, (i) {
      final angle = -math.pi + i * (2 * math.pi / n);
      final base = 2.5 + math.sin(angle * 3 + _t * 0.05) * 0.5;
      return base + _rnd.nextDouble() * 0.05;
    });
    _publish(topic, 'sensor_msgs/msg/LaserScan', {
      'header': _header('base_link'),
      'angle_min': -math.pi,
      'angle_max': math.pi,
      'angle_increment': 2 * math.pi / n,
      'time_increment': 0.0,
      'scan_time': 0.1,
      'range_min': 0.12,
      'range_max': 10.0,
      'ranges': ranges,
      'intensities': <double>[],
    });
  }

  void _publishAmclPose(String topic) {
    final half = _odomYaw / 2;
    _publish(topic, 'geometry_msgs/msg/PoseWithCovarianceStamped', {
      'header': _header('map'),
      'pose': {
        'pose': {
          'position': {'x': _odomX, 'y': _odomY, 'z': 0.0},
          'orientation': {
            'x': 0.0,
            'y': 0.0,
            'z': math.sin(half),
            'w': math.cos(half),
          },
        },
        'covariance': List.filled(36, 0.0),
      },
    });
  }

  void _publishPlan(String topic) {
    final poses = <Map<String, dynamic>>[];
    for (var i = 0; i < 20; i++) {
      final t = i * 0.1;
      poses.add({
        'header': _header('map'),
        'pose': {
          'position': {
            'x': _odomX + math.cos(_odomYaw) * t,
            'y': _odomY + math.sin(_odomYaw) * t,
            'z': 0.0,
          },
          'orientation': {'x': 0.0, 'y': 0.0, 'z': 0.0, 'w': 1.0},
        },
      });
    }
    _publish(topic, 'nav_msgs/msg/Path', {
      'header': _header('map'),
      'poses': poses,
    });
  }

  Map<String, dynamic> _header(String frame) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'frame_id': frame,
      'stamp': {'sec': now ~/ 1000, 'nanosec': (now % 1000) * 1000000},
    };
  }

  void _onService(Map<String, dynamic> m) {
    final id = m['id'];
    final service = m['service'] as String;
    Map<String, dynamic> result;
    if (service.endsWith('/amr/estop')) {
      final engage = (m['args'] as Map?)?['engage'] == true;
      result = {'success': true, 'message': engage ? 'engaged' : 'released'};
    } else if (service.endsWith('/amr/slam/control')) {
      final action = (m['args'] as Map?)?['action'] ?? 'noop';
      result = {'success': true, 'message': 'slam $action ok (mock)'};
    } else if (service.endsWith('/amr/bag/control')) {
      final action = (m['args'] as Map?)?['action'] ?? 'noop';
      result = {
        'success': true,
        'message': 'bag $action ok (mock)',
        'bags': ['demo_bag_a', 'demo_bag_b'],
      };
    } else if (service.endsWith('/save_map')) {
      result = {'success': true, 'message': 'saved (mock)'};
    } else if (service.endsWith('/set_parameters')) {
      final params = (m['args'] as Map?)?['parameters'] as List? ?? const [];
      result = {
        'results': [
          for (final _ in params) {'successful': true, 'reason': ''}
        ],
      };
    } else if (service.endsWith('/get_parameters')) {
      final names = (m['args'] as Map?)?['names'] as List? ?? const [];
      result = {
        'values': [
          for (final _ in names) {'type': 3, 'double_value': 0.5}
        ],
      };
    } else {
      result = {'success': false, 'message': 'unknown service $service'};
    }
    _send({
      'op': 'service_response',
      if (id != null) 'id': id,
      'service': service,
      'values': result,
      'result': true,
    });
  }

  void _onActionGoal(Map<String, dynamic> m) {
    final id = m['id'] as String? ?? 'goal_${_rnd.nextInt(1 << 30)}';
    final actionName = m['action'] as String;

    Future.delayed(const Duration(milliseconds: 200), () {
      _send({
        'op': 'action_feedback',
        'id': id,
        'action': actionName,
        'values': {'distance_remaining': 1.0},
      });
    });
    Future.delayed(const Duration(seconds: 2), () {
      _send({
        'op': 'action_result',
        'id': id,
        'action': actionName,
        'status': 4, // succeeded
        'values': {'result': 'ok'},
      });
    });
  }
}

class _Sub {
  _Sub(this.id, this.topic);
  final String id;
  final String topic;
}
