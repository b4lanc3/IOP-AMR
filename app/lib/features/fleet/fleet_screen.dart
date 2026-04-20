import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/connection_provider.dart';
import '../../core/ros/ros_client.dart';
import '../../core/storage/models/robot_profile.dart';
import '../../l10n/app_localizations.dart';

class FleetScreen extends ConsumerWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final robotsAsync = ref.watch(robotProfilesProvider);
    final active = ref.watch(activeRosClientProvider);
    final statusAsync = ref.watch(activeRosStatusProvider);

    return robotsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text(l10n.fleetError(e.toString()))),
      data: (robots) {
        if (robots.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hub_outlined,
                    size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                Text(l10n.fleetEmpty),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => context.go('/connection'),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.fleetAddRobot),
                ),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: robots.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, i) {
            final r = robots[i];
            final isActive = active?.profile.id == r.id;
            final status = isActive
                ? (statusAsync.value ?? active!.currentStatus)
                : RosConnectionStatus.disconnected;
            return _RobotCard(
              l10n: l10n,
              profile: r,
              isActive: isActive,
              status: status,
              onSwitch: () async {
                await ref
                    .read(activeRobotControllerProvider)
                    .connectTo(r);
              },
              onOpenConnection: () => context.go('/connection'),
            );
          },
        );
      },
    );
  }
}

class _RobotCard extends StatelessWidget {
  const _RobotCard({
    required this.l10n,
    required this.profile,
    required this.isActive,
    required this.status,
    required this.onSwitch,
    required this.onOpenConnection,
  });

  final AppLocalizations l10n;
  final RobotProfile profile;
  final bool isActive;
  final RosConnectionStatus status;
  final VoidCallback onSwitch;
  final VoidCallback onOpenConnection;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      RosConnectionStatus.connected => (Colors.green, l10n.statusOnline),
      RosConnectionStatus.connecting => (Colors.orange, l10n.statusConnecting),
      RosConnectionStatus.error => (Colors.red, l10n.statusError),
      RosConnectionStatus.disconnected => (Colors.grey, l10n.statusOffline),
    };
    return Card(
      elevation: isActive ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
          width: isActive ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isActive ? null : onSwitch,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isActive
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                    child: const Icon(Icons.smart_toy_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name,
                            style:
                                Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                                backgroundColor: color, radius: 4),
                            const SizedBox(width: 6),
                            Text(isActive ? label : l10n.fleetStandby,
                                style:
                                    Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InfoRow(
                  icon: Icons.link, text: profile.websocketUrl),
              _InfoRow(
                icon: Icons.label_outline,
                text:
                    'ns: ${profile.namespace.isEmpty ? "—" : profile.namespace}',
              ),
              if (profile.host.isNotEmpty)
                _InfoRow(icon: Icons.dns, text: profile.host),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: isActive ? null : onSwitch,
                      icon: Icon(
                          isActive ? Icons.check : Icons.swap_horiz),
                      label: Text(
                          isActive
                              ? l10n.fleetCurrentActive
                              : l10n.fleetSwitchToRobot),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l10n.fleetOpenConnectionTooltip,
                    onPressed: onOpenConnection,
                    icon: const Icon(Icons.settings_ethernet),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon,
              size: 14, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
