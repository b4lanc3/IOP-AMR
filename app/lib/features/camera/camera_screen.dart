import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ros/ros_client.dart';
import '../../l10n/app_localizations.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final _rgbTopic = TextEditingController(text: '/camera/color/image_raw');
  final _depthTopic =
      TextEditingController(text: '/camera/depth/image_raw');
  int _rgbEpoch = 0;
  int _depthEpoch = 0;

  @override
  void dispose() {
    _rgbTopic.dispose();
    _depthTopic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(activeRosClientProvider);
    final profile = client?.profile;
    final l10n = AppLocalizations.of(context);
    if (profile == null) {
      return Center(child: Text(l10n.cameraNoRobot));
    }
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rgbTopic,
                    decoration:
                        InputDecoration(labelText: l10n.cameraRgbTopic),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _depthTopic,
                    decoration:
                        InputDecoration(labelText: l10n.cameraDepthTopic),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: l10n.cameraReloadTooltip,
                  onPressed: () => setState(() {
                    _rgbEpoch++;
                    _depthEpoch++;
                  }),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          TabBar(
            tabs: [
              Tab(text: l10n.cameraTabRgb),
              Tab(text: l10n.cameraTabDepth),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MjpegView(
                  key: ValueKey('rgb-$_rgbEpoch'),
                  url: profile.videoStreamUrl(_rgbTopic.text.trim()),
                  onRetry: () => setState(() => _rgbEpoch++),
                  l10n: l10n,
                ),
                _MjpegView(
                  key: ValueKey('depth-$_depthEpoch'),
                  url: profile.videoStreamUrl(_depthTopic.text.trim()),
                  onRetry: () => setState(() => _depthEpoch++),
                  l10n: l10n,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MjpegView extends StatelessWidget {
  const _MjpegView({
    super.key,
    required this.url,
    required this.onRetry,
    required this.l10n,
  });
  final String url;
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Mjpeg(
                isLive: true,
                stream: url,
                error: (context, err, stack) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white70, size: 48),
                      const SizedBox(height: 8),
                      Text(l10n.cameraStreamError(err.toString()),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.cameraRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black.withValues(alpha: 0.5),
              child: Text(
                url,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
