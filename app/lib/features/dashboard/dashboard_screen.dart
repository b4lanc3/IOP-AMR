import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ros/msg_types.dart';
import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/ui_kit.dart';
import '../../l10n/app_localizations.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  RosSubscription? _batterySub;
  RosSubscription? _odomSub;
  RosSubscription? _statsSub;
  RosSubscription? _poseSub;

  BatteryState? _battery;
  Odometry? _odom;
  SystemStats? _stats;
  PoseStamped? _amclPose;

  RosConnectionStatus _lastStatus = RosConnectionStatus.disconnected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _wireIfReady());
  }

  void _wireIfReady() {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    if (client.currentStatus == RosConnectionStatus.connected) _wire();
  }

  void _wire() {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    _batterySub?.cancel();
    _odomSub?.cancel();
    _statsSub?.cancel();
    _poseSub?.cancel();

    _batterySub = client.subscribeRaw(
      topic: RosTopics.battery,
      type: RosTypes.battery,
    );
    _batterySub!.stream.listen((m) {
      if (!mounted) return;
      setState(() => _battery = BatteryState.fromJson(m));
    });

    _odomSub = client.subscribeRaw(
      topic: RosTopics.odom,
      type: RosTypes.odometry,
      throttleRateMs: 200,
    );
    _odomSub!.stream.listen((m) {
      if (!mounted) return;
      setState(() => _odom = Odometry.fromJson(m));
    });

    _statsSub = client.subscribeRaw(
      topic: RosTopics.systemStats,
      type: RosTypes.systemStats,
      throttleRateMs: 250,
      queueLength: 1,
    );
    _statsSub!.stream.listen((m) {
      if (!mounted) return;
      setState(() => _stats = SystemStats.fromJson(m));
    });

    _poseSub = client.subscribeRaw(
      topic: RosTopics.amclPose,
      type: RosTypes.poseWithCovariance,
      throttleRateMs: 300,
    );
    _poseSub!.stream.listen((m) {
      if (!mounted) return;
      final poseMap = (m['pose'] as Map<String, dynamic>)['pose']
          as Map<String, dynamic>;
      setState(() => _amclPose = PoseStamped(
            Header.fromJson(m['header'] as Map<String, dynamic>),
            Pose.fromJson(poseMap),
          ));
    });
  }

  @override
  void dispose() {
    _batterySub?.cancel();
    _odomSub?.cancel();
    _statsSub?.cancel();
    _poseSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<RosConnectionStatus>>(activeRosStatusProvider,
        (prev, next) {
      final s = next.value ?? RosConnectionStatus.disconnected;
      if (s != _lastStatus) {
        _lastStatus = s;
        if (s == RosConnectionStatus.connected) _wire();
      }
    });

    final client = ref.watch(activeRosClientProvider);
    final statusAsync = ref.watch(activeRosStatusProvider);
    final status = statusAsync.value ?? client?.currentStatus;
    final connected = status == RosConnectionStatus.connected;
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, c) {
        // 1 / 2 / 4 cột — responsive theo width.
        final cross = c.maxWidth >= 1280
            ? 4
            : c.maxWidth >= 820
                ? 2
                : c.maxWidth >= 520
                    ? 2
                    : 1;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _DashboardHero(
                  robotName: client?.profile.name ?? l10n.dashboardNoRobot,
                  host: client?.profile.host ?? '—',
                  connected: connected,
                  battery: _battery,
                  l10n: l10n,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: l10n.dashboardLiveStatus,
                  subtitle: l10n.dashboardLiveStatusSubtitle,
                  icon: Icons.insights_rounded,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverGrid.count(
                crossAxisCount: cross,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: cross == 1 ? 1.8 : 1.45,
                children: [
                  _BatteryCard(battery: _battery, l10n: l10n),
                  _VelocityCard(odom: _odom, l10n: l10n),
                  _PoseCard(odom: _odom, amcl: _amclPose, l10n: l10n),
                  _SystemCard(stats: _stats, l10n: l10n),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Hero banner cho dashboard: tên robot, host, trạng thái, pin tóm tắt.
class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.robotName,
    required this.host,
    required this.connected,
    required this.battery,
    required this.l10n,
  });

  final String robotName;
  final String host;
  final bool connected;
  final BatteryState? battery;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = battery?.percent;
    return HeroBanner(
      title: robotName,
      subtitle: connected
          ? l10n.dashboardOnlineHost(host)
          : l10n.dashboardOfflineHint,
      icon: Icons.precision_manufacturing_rounded,
      chips: [
        _HeroChip(
          icon: Icons.cable_rounded,
          label: host,
          color: scheme.secondary,
        ),
        _HeroChip(
          icon: connected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
          label: connected ? l10n.statusOnline : l10n.statusOffline,
          color: connected ? AppTheme.brandSuccess : scheme.outline,
        ),
        if (pct != null)
          _HeroChip(
            icon: Icons.battery_charging_full_rounded,
            label: l10n.dashboardBatteryPercent(pct.toStringAsFixed(0)),
            color: pct < 20
                ? AppTheme.brandDanger
                : pct < 50
                    ? AppTheme.brandWarning
                    : AppTheme.brandSuccess,
          ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _BatteryCard extends StatelessWidget {
  const _BatteryCard({required this.battery, required this.l10n});
  final BatteryState? battery;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final b = battery;
    final pct = (b?.percent ?? 0).clamp(0.0, 100.0);
    final accent = pct < 20
        ? AppTheme.brandDanger
        : pct < 50
            ? AppTheme.brandWarning
            : AppTheme.brandSuccess;
    return MetricCard(
      icon: Icons.battery_charging_full_rounded,
      title: l10n.dashboardBattery,
      value: b == null ? '—' : pct.toStringAsFixed(0),
      unit: b == null ? null : '%',
      subtitle: b == null
          ? '--.- V / --.- A'
          : '${b.voltage.toStringAsFixed(1)} V · '
              '${b.current.toStringAsFixed(2)} A'
              '${b.charging ? "  ·  ⚡ ${l10n.dashboardBatteryCharging}" : ""}',
      progress: b == null ? 0 : pct / 100,
      accent: accent,
    );
  }
}

class _VelocityCard extends StatelessWidget {
  const _VelocityCard({required this.odom, required this.l10n});
  final Odometry? odom;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final lin = odom?.twist.linear.x ?? 0;
    final ang = odom?.twist.angular.z ?? 0;
    return MetricCard(
      icon: Icons.speed_rounded,
      title: l10n.dashboardVelocity,
      value: lin.toStringAsFixed(2),
      unit: 'm/s',
      subtitle: l10n.dashboardVelocityOmega(ang.toStringAsFixed(2)),
      progress: (lin.abs() / 1.5).clamp(0.0, 1.0),
      accent: AppTheme.brandAccent,
    );
  }
}

class _PoseCard extends StatelessWidget {
  const _PoseCard(
      {required this.odom, required this.amcl, required this.l10n});
  final Odometry? odom;
  final PoseStamped? amcl;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final p = odom?.pose.position;
    final yaw = odom?.pose.orientation.yaw ?? 0;
    final ap = amcl?.pose.position;
    final ayaw = amcl?.pose.orientation.yaw;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const GradientIconBadge(
                  icon: Icons.place_rounded,
                  color: AppTheme.brandPrimary,
                  size: 34,
                  radius: 10,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.dashboardPoseTitle.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PoseRow(
              label: l10n.dashboardPoseOdom,
              x: p?.x,
              y: p?.y,
              yaw: yaw,
              color: AppTheme.brandAccent,
            ),
            const SizedBox(height: 6),
            _PoseRow(
              label: l10n.dashboardPoseAmcl,
              x: ap?.x,
              y: ap?.y,
              yaw: ayaw,
              color: AppTheme.brandPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PoseRow extends StatelessWidget {
  const _PoseRow({
    required this.label,
    required this.x,
    required this.y,
    required this.yaw,
    required this.color,
  });
  final String label;
  final double? x;
  final double? y;
  final double? yaw;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    String fmt(double? v) => v == null ? '—' : v.toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: t.textTheme.labelMedium?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _PoseField(label: 'x', value: fmt(x)),
          const SizedBox(width: 10),
          _PoseField(label: 'y', value: fmt(y)),
          const SizedBox(width: 10),
          _PoseField(label: 'yaw', value: fmt(yaw)),
        ],
      ),
    );
  }
}

class _PoseField extends StatelessWidget {
  const _PoseField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: t.textTheme.bodySmall?.copyWith(
            color: t.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: t.textTheme.bodyMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SystemCard extends StatelessWidget {
  const _SystemCard({required this.stats, required this.l10n});
  final SystemStats? stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GradientIconBadge(
                  icon: Icons.memory_rounded,
                  color: scheme.tertiary,
                  size: 34,
                  radius: 10,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.dashboardSystemTitle.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                ),
                const Spacer(),
                if (s != null)
                  Text(
                    '${s.cpuTempC.toStringAsFixed(0)}° / '
                    '${s.gpuTempC.toStringAsFixed(0)}°C',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _sysRow(context, 'CPU', s?.cpuPercent, AppTheme.brandAccent),
            const SizedBox(height: 6),
            _sysRow(context, 'GPU', s?.gpuPercent, AppTheme.brandPrimary),
            const SizedBox(height: 6),
            _sysRow(
              context,
              'RAM',
              s == null ? null : (s.ramUsedMb / s.ramTotalMb) * 100,
              AppTheme.brandSuccess,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sysRow(
      BuildContext context, String label, double? value, Color color) {
    final v = value ?? 0;
    final t = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: t.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: t.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (v / 100).clamp(0, 1),
              minHeight: 6,
              color: color,
              backgroundColor:
                  t.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(
            value == null ? '—' : '${v.toStringAsFixed(0)}%',
            textAlign: TextAlign.end,
            style: t.textTheme.labelMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
