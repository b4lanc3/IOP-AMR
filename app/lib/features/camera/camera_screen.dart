import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ros/ros_client.dart';

class CameraScreen extends ConsumerWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(activeRosClientProvider);
    final profile = client?.profile;
    if (profile == null) {
      return const Center(child: Text('Chưa chọn robot'));
    }
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [Tab(text: 'RGB'), Tab(text: 'Depth')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MjpegView(url: profile.videoStreamUrl('/camera/color/image_raw')),
                _MjpegView(url: profile.videoStreamUrl('/camera/depth/image_raw')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MjpegView extends StatelessWidget {
  const _MjpegView({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Mjpeg(
          isLive: true,
          stream: url,
          error: (context, err, stack) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Không lấy được stream:\n$err',
                style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
