import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/storage/hive_boxes.dart';
import '../../core/storage/models/app_settings.dart';
import '../../core/storage/models/gamepad_profile.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final ctrl = ref.read(appSettingsProvider.notifier);
    final profiles = HiveBoxes.gamepadProfiles.values.toList();
    final activeProfile = profiles.firstWhere(
      (p) => p.id == settings.activeGamepadProfileId,
      orElse: () => profiles.isNotEmpty
          ? profiles.first
          : GamepadProfile(id: 'none', name: 'none'),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          title: 'Giao diện',
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: const Text('Chủ đề'),
              trailing: DropdownButton<ThemeMode>(
                value: settings.themeMode,
                items: const [
                  DropdownMenuItem(
                      value: ThemeMode.system, child: Text('Theo hệ thống')),
                  DropdownMenuItem(
                      value: ThemeMode.light, child: Text('Sáng')),
                  DropdownMenuItem(
                      value: ThemeMode.dark, child: Text('Tối')),
                ],
                onChanged: (v) =>
                    v == null ? null : ctrl.update((s) => s.copyWith(themeMode: v)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.straighten),
              title: const Text('Đơn vị hiển thị'),
              trailing: DropdownButton<DisplayUnits>(
                value: settings.units,
                items: const [
                  DropdownMenuItem(
                      value: DisplayUnits.metric,
                      child: Text('Metric (m, m/s)')),
                  DropdownMenuItem(
                      value: DisplayUnits.imperial,
                      child: Text('Imperial (ft, ft/s)')),
                ],
                onChanged: (v) =>
                    v == null ? null : ctrl.update((s) => s.copyWith(units: v)),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.grid_on),
              title: const Text('Hiện lưới trên LiDAR'),
              value: settings.showGridOnLidar,
              onChanged: (v) =>
                  ctrl.update((s) => s.copyWith(showGridOnLidar: v)),
            ),
          ],
        ),
        _Section(
          title: 'Kết nối',
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.refresh),
              title: const Text('Auto-reconnect'),
              subtitle: const Text(
                  'Tự kết nối lại nếu rosbridge rớt, exponential backoff'),
              value: settings.autoReconnect,
              onChanged: (v) =>
                  ctrl.update((s) => s.copyWith(autoReconnect: v)),
            ),
          ],
        ),
        _Section(
          title: 'Điều khiển',
          children: [
            _SliderTile(
              label: 'Tốc độ tuyến tính tối đa',
              unit: 'm/s',
              min: 0.05,
              max: 2.0,
              value: settings.defaultMaxLinear,
              onChanged: (v) =>
                  ctrl.update((s) => s.copyWith(defaultMaxLinear: v)),
            ),
            _SliderTile(
              label: 'Tốc độ quay tối đa',
              unit: 'rad/s',
              min: 0.1,
              max: 3.5,
              value: settings.defaultMaxAngular,
              onChanged: (v) =>
                  ctrl.update((s) => s.copyWith(defaultMaxAngular: v)),
            ),
            _SliderTile(
              label: 'Tần số publish /cmd_vel',
              unit: 'Hz',
              min: 5,
              max: 40,
              divisions: 35,
              value: settings.teleopPublishHz.toDouble(),
              onChanged: (v) => ctrl
                  .update((s) => s.copyWith(teleopPublishHz: v.round())),
            ),
          ],
        ),
        _Section(
          title: 'Gamepad',
          trailing: IconButton(
            tooltip: 'Tạo profile mới',
            icon: const Icon(Icons.add),
            onPressed: _createProfile,
          ),
          children: [
            for (final p in profiles)
              RadioListTile<String>(
                value: p.id,
                groupValue: settings.activeGamepadProfileId,
                onChanged: (v) => ctrl.update(
                    (s) => s.copyWith(activeGamepadProfileId: v)),
                title: Text(p.name),
                subtitle: Text(
                  'lin=${p.linearAxisKey}${p.invertLinear ? "⁻" : ""}  '
                  'ang=${p.angularAxisKey}${p.invertAngular ? "⁻" : ""}  '
                  'dz=${p.deadzone.toStringAsFixed(2)}',
                ),
                secondary: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Sửa',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editProfile(p),
                    ),
                    if (profiles.length > 1)
                      IconButton(
                        tooltip: 'Xoá',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteProfile(p),
                      ),
                  ],
                ),
              ),
            if (profiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Đang dùng: ${activeProfile.name}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
        _Section(
          title: 'Ứng dụng',
          children: [
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snap) {
                final info = snap.data;
                return ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Phiên bản'),
                  subtitle: Text(
                    info == null
                        ? 'Đang tải…'
                        : '${info.version} (${info.buildNumber}) · ${info.appName}',
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Cài đặt Windows'),
              subtitle: const Text(
                'Bản phát hành: chạy dart run msix:create trong thư mục app '
                'để tạo file .msix, hoặc dùng ZIP thư mục Release (xem scripts/).',
              ),
              isThreeLine: true,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _createProfile() async {
    final id = const Uuid().v4();
    final profile = GamepadProfile(id: id, name: 'Profile ${DateTime.now().millisecondsSinceEpoch % 100000}');
    await HiveBoxes.gamepadProfiles.put(id, profile);
    if (!mounted) return;
    _editProfile(profile);
  }

  Future<void> _deleteProfile(GamepadProfile p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá profile?'),
        content: Text('Xoá "${p.name}"? Không thể khôi phục.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xoá')),
        ],
      ),
    );
    if (confirm == true) {
      await HiveBoxes.gamepadProfiles.delete(p.id);
      final settings = ref.read(appSettingsProvider);
      if (settings.activeGamepadProfileId == p.id) {
        final next = HiveBoxes.gamepadProfiles.values.firstOrNull;
        ref
            .read(appSettingsProvider.notifier)
            .update((s) => s.copyWith(activeGamepadProfileId: next?.id));
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _editProfile(GamepadProfile p) async {
    final result = await showDialog<GamepadProfile>(
      context: context,
      builder: (_) => _GamepadProfileDialog(initial: p),
    );
    if (result != null) {
      await HiveBoxes.gamepadProfiles.put(result.id, result);
      if (mounted) setState(() {});
    }
  }
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title, required this.children, this.trailing});
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.divisions,
  });
  final String label;
  final String unit;
  final double min;
  final double max;
  final double value;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label)),
            Text('${value.toStringAsFixed(2)} $unit',
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ]),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _GamepadProfileDialog extends StatefulWidget {
  const _GamepadProfileDialog({required this.initial});
  final GamepadProfile initial;

  @override
  State<_GamepadProfileDialog> createState() =>
      _GamepadProfileDialogState();
}

class _GamepadProfileDialogState extends State<_GamepadProfileDialog> {
  late TextEditingController _name;
  late TextEditingController _linKey;
  late TextEditingController _angKey;
  late bool _invLin;
  late bool _invAng;
  late double _linScale;
  late double _angScale;
  late double _deadzone;
  late Map<String, String> _buttons;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p.name);
    _linKey = TextEditingController(text: p.linearAxisKey);
    _angKey = TextEditingController(text: p.angularAxisKey);
    _invLin = p.invertLinear;
    _invAng = p.invertAngular;
    _linScale = p.linearScale;
    _angScale = p.angularScale;
    _deadzone = p.deadzone;
    _buttons = Map.of(p.buttonActions);
  }

  @override
  void dispose() {
    _name.dispose();
    _linKey.dispose();
    _angKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sửa gamepad profile',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Tên profile'),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _linKey,
                      decoration: const InputDecoration(
                          labelText: 'Linear axis key (ví dụ l.y)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _angKey,
                      decoration: const InputDecoration(
                          labelText: 'Angular axis key (ví dụ r.x)'),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Invert linear'),
                      value: _invLin,
                      onChanged: (v) => setState(() => _invLin = v),
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Invert angular'),
                      value: _invAng,
                      onChanged: (v) => setState(() => _invAng = v),
                    ),
                  ),
                ]),
                _slider('Linear scale', _linScale, 0.1, 2.0,
                    (v) => setState(() => _linScale = v)),
                _slider('Angular scale', _angScale, 0.1, 3.5,
                    (v) => setState(() => _angScale = v)),
                _slider('Deadzone', _deadzone, 0, 0.3,
                    (v) => setState(() => _deadzone = v)),
                const SizedBox(height: 8),
                const Text('Map nút bấm',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                for (final e in _buttons.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      SizedBox(width: 90, child: Text(e.key)),
                      Expanded(
                        child: TextFormField(
                          initialValue: e.value,
                          decoration: const InputDecoration(isDense: true),
                          onChanged: (v) => _buttons[e.key] = v,
                        ),
                      ),
                    ]),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Huỷ')),
                    const SizedBox(width: 8),
                    FilledButton(
                        onPressed: () => Navigator.pop(
                              context,
                              GamepadProfile(
                                id: widget.initial.id,
                                name: _name.text.trim().isEmpty
                                    ? widget.initial.name
                                    : _name.text.trim(),
                                linearAxisKey: _linKey.text.trim(),
                                angularAxisKey: _angKey.text.trim(),
                                invertLinear: _invLin,
                                invertAngular: _invAng,
                                linearScale: _linScale,
                                angularScale: _angScale,
                                deadzone: _deadzone,
                                buttonActions: _buttons,
                              ),
                            ),
                        child: const Text('Lưu')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(2)}'),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
