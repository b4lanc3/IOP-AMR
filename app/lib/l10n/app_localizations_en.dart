// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'IOP-AMR Control';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navCamera => 'Camera';

  @override
  String get navLidar => 'LiDAR';

  @override
  String get navMap => 'Map';

  @override
  String get navMapping => 'Mapping';

  @override
  String get navWaypoints => 'Waypoints';

  @override
  String get navMonitoring => 'Monitor';

  @override
  String get navParams => 'Params';

  @override
  String get navLogs => 'Logs';

  @override
  String get navFleet => 'Fleet';

  @override
  String get navSettings => 'Settings';

  @override
  String get shellBrandSubtitle => 'Control suite';

  @override
  String get shellDrawerSubtitle => 'Control & monitoring';

  @override
  String get shellSwapRobotTooltip => 'Switch robot';

  @override
  String get shellMenuTooltip => 'Menu';

  @override
  String get statusNotConnected => 'Not connected';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusConnecting => 'Connecting…';

  @override
  String get statusError => 'Error';

  @override
  String get statusOffline => 'Offline';

  @override
  String get estopFabOn => 'E-STOP ON';

  @override
  String get estopFab => 'E-STOP';

  @override
  String estopServiceError(String error) {
    return 'E-stop service error: $error';
  }

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsLanguageLabel => 'Interface language';

  @override
  String get settingsLanguageVietnamese => 'Vietnamese';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsUnits => 'Display units';

  @override
  String get settingsUnitsMetric => 'Metric (m, m/s)';

  @override
  String get settingsUnitsImperial => 'Imperial (ft, ft/s)';

  @override
  String get settingsLidarGrid => 'Show grid on LiDAR';

  @override
  String get settingsSectionConnection => 'Connection';

  @override
  String get settingsAutoReconnect => 'Auto-reconnect';

  @override
  String get settingsAutoReconnectSubtitle =>
      'Reconnect if rosbridge drops, exponential backoff';

  @override
  String get settingsSectionControl => 'Control';

  @override
  String get settingsMaxLinear => 'Max linear speed';

  @override
  String get settingsMaxAngular => 'Max angular speed';

  @override
  String get settingsCmdVelHz => '/cmd_vel publish rate';

  @override
  String get settingsSectionGamepad => 'Gamepad';

  @override
  String get settingsNewProfileTooltip => 'New profile';

  @override
  String get settingsEditTooltip => 'Edit';

  @override
  String get settingsDeleteTooltip => 'Delete';

  @override
  String settingsUsingProfile(String name) {
    return 'Active: $name';
  }

  @override
  String get settingsSectionApp => 'Application';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsVersionLoading => 'Loading…';

  @override
  String get settingsWindowsInstall => 'Windows install';

  @override
  String get settingsWindowsInstallSubtitle =>
      'Release: run dart run msix:create in the app folder to build .msix, or use the Release ZIP folder (see scripts/).';

  @override
  String get settingsDeleteProfileTitle => 'Delete profile?';

  @override
  String settingsDeleteProfileBody(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonOk => 'OK';

  @override
  String get gamepadEditTitle => 'Edit gamepad profile';

  @override
  String get gamepadProfileName => 'Profile name';

  @override
  String get gamepadLinearAxis => 'Linear axis key (e.g. l.y)';

  @override
  String get gamepadAngularAxis => 'Angular axis key (e.g. r.x)';

  @override
  String get gamepadInvertLinear => 'Invert linear';

  @override
  String get gamepadInvertAngular => 'Invert angular';

  @override
  String get gamepadButtonMap => 'Button mapping';

  @override
  String get gamepadLinearScale => 'Linear scale';

  @override
  String get gamepadAngularScale => 'Angular scale';

  @override
  String get gamepadDeadzone => 'Deadzone';

  @override
  String get connectionTitle => 'Connect robot';

  @override
  String get connectionScanMdns => 'Scan mDNS';

  @override
  String get connectionSettings => 'Settings';

  @override
  String connectionScanDone(int count) {
    return 'Scan complete: $count robots';
  }

  @override
  String connectionDeleteRobotTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get connectionDeleteRobotBody => 'This action cannot be undone.';

  @override
  String connectionFailedRetry(String name) {
    return 'Could not connect to $name — retrying…';
  }

  @override
  String get connectionHeroTitle => 'Fleet & connection';

  @override
  String get connectionHeroSubtitle =>
      'Pick a robot to work with, or add an IP manually / scan mDNS. After rosbridge connects, this device remembers the profile.';

  @override
  String connectionRobotsSaved(int count) {
    return '$count robots saved';
  }

  @override
  String get connectionRosbridgeChip => 'rosbridge 9090 · video 8080';

  @override
  String connectionError(String message) {
    return 'Error: $message';
  }

  @override
  String get connectionAddIp => 'Add IP';

  @override
  String get connectionPingTooltip => 'Test ping';

  @override
  String get connectionEditTooltip => 'Edit';

  @override
  String get connectionDeleteTooltip => 'Delete';

  @override
  String get connectionConnect => 'Connect';

  @override
  String get connectionPingUnreachable => 'unreachable';

  @override
  String connectionNamespacePill(String value) {
    return 'ns $value';
  }

  @override
  String connectionVideoPill(int port) {
    return 'video $port';
  }

  @override
  String connectionPingPill(String result) {
    return 'ping $result';
  }

  @override
  String get connectionNetworkHelpTitle =>
      'Network & robots: LAN, Tailscale, remote';

  @override
  String get connectionNetworkHelpSubtitle => 'When to use LAN IP vs 100.x…';

  @override
  String get connectionHintLanTitle =>
      'Same Wi‑Fi / LAN (often no Internet needed)';

  @override
  String get connectionHintLanBody =>
      'PC and Jetson on the same switch/Wi‑Fi: use the robot’s LAN IP (e.g. 192.168.x.x). Ensure rosbridge listens on 0.0.0.0:9090 on Jetson. No Tailscale required.';

  @override
  String get connectionHintTailscaleTitle =>
      'Tailscale (100.x.x.x — e.g. preset DDE-AMR)';

  @override
  String get connectionHintTailscaleBody =>
      'Both machines on the same tailnet: connect via the Tailscale IP assigned to Jetson. Use when laptop and robot differ subnet or are remote. For same room “offline” work, prefer LAN over 100.x.';

  @override
  String get connectionHintNotTailscaleTitle => 'Not on the same Tailscale';

  @override
  String get connectionHintNotTailscaleBody =>
      'Join the same tailnet, or use another VPN (WireGuard, ZeroTier…), or expose rosbridge through your router (NAT + security). In the app: add a profile with the right IP/port.';

  @override
  String get connectionEmptyTitle => 'No robots yet';

  @override
  String get connectionEmptyBody =>
      'Add the Jetson IP (rosbridge is usually port 9090) or scan mDNS if the robot advertises on the LAN.';

  @override
  String get connectionTipAddIp => 'Add IP — enter host, port, namespace';

  @override
  String get connectionTipMdns =>
      'Scan mDNS — find robots on the local network';

  @override
  String get connectionDialogEditTitle => 'Edit robot';

  @override
  String get connectionDialogAddTitle => 'Add robot';

  @override
  String get connectionDisplayName => 'Display name';

  @override
  String get connectionHost => 'IP / hostname';

  @override
  String get connectionRosbridgePort => 'rosbridge port';

  @override
  String get connectionVideoPort => 'video port';

  @override
  String get connectionNamespaceOptional => 'Namespace (optional)';

  @override
  String get connectionNamespaceHint => 'e.g. /robot_1';

  @override
  String get connectionAuthTokenOptional => 'Auth token (optional)';

  @override
  String get connectionUseWss => 'Use wss:// / https://';

  @override
  String get connectionNameRequired => 'Enter a name';

  @override
  String get connectionHostRequired => 'Enter host';

  @override
  String get dashboardNoRobot => 'No robot selected';

  @override
  String get dashboardLiveStatus => 'Live status';

  @override
  String get dashboardLiveStatusSubtitle =>
      'Data from rosbridge topics (battery, velocity, pose, CPU/GPU).';

  @override
  String dashboardOnlineHost(String host) {
    return 'Online · $host';
  }

  @override
  String get dashboardOfflineHint =>
      'Offline — check rosbridge or pick another robot';

  @override
  String dashboardBatteryPercent(String pct) {
    return '$pct% battery';
  }

  @override
  String get dashboardBatteryCharging => 'charging';

  @override
  String get dashboardBattery => 'Battery';

  @override
  String get dashboardVelocity => 'Velocity';

  @override
  String dashboardVelocityOmega(String value) {
    return 'ω: $value rad/s';
  }

  @override
  String get dashboardPoseOdom => 'odom';

  @override
  String get dashboardPoseAmcl => 'amcl (map)';

  @override
  String get dashboardPoseTitle => 'Pose';

  @override
  String get dashboardSystemTitle => 'System';

  @override
  String get cameraNoRobot => 'No robot selected';

  @override
  String get cameraRgbTopic => 'RGB topic';

  @override
  String get cameraDepthTopic => 'Depth topic';

  @override
  String get cameraReloadTooltip => 'Reload both streams';

  @override
  String get cameraTabRgb => 'RGB';

  @override
  String get cameraTabDepth => 'Depth';

  @override
  String get lidarRange => 'Range';

  @override
  String get lidarResetView => 'Reset view';

  @override
  String lidarScaleLabel(String value) {
    return '$value px/m';
  }

  @override
  String get mappingTitle => 'SLAM Mapping';

  @override
  String get mappingRunning => 'Mapping';

  @override
  String get mappingMapName => 'Map name';

  @override
  String get mappingStart => 'Start';

  @override
  String get mappingStop => 'Stop';

  @override
  String get mappingSaveMap => 'Save map';

  @override
  String get mappingReset => 'Reset';

  @override
  String get mappingOpenMap => 'View live on Map';

  @override
  String mappingSlamResult(String action, String message) {
    return 'SLAM $action: $message';
  }

  @override
  String mappingError(String message) {
    return 'Error: $message';
  }

  @override
  String mappingSaveRequested(String name) {
    return 'Save requested for map \"$name\"';
  }

  @override
  String mappingSaveError(String message) {
    return 'Save error: $message';
  }

  @override
  String get mappingHowToTitle => 'Mapping workflow';

  @override
  String get mappingHowToBody =>
      '1. Tap Start to run slam_toolbox.\n2. Open Map or Teleop and drive slowly around the area.\n3. When the map looks good, return here and tap Save map.\n4. After saving, you can Stop SLAM and switch to navigation mode.';

  @override
  String get logsTitle => 'Rosbag recorder';

  @override
  String get logsBagName => 'Bag name';

  @override
  String get logsTopicsComma => 'Topics (comma-separated)';

  @override
  String get logsStart => 'Start';

  @override
  String get logsStop => 'Stop';

  @override
  String get logsRefreshList => 'Refresh list';

  @override
  String get logsAvailableBags => 'Available bags';

  @override
  String logsBagCount(int count) {
    return '$count bags';
  }

  @override
  String get logsEmpty =>
      'No bags yet. Tap \"Refresh list\" or record a new bag.';

  @override
  String get logsNotConnected => 'Not connected to robot';

  @override
  String logsBagAction(String action, String message) {
    return 'Bag $action: $message';
  }

  @override
  String logsErrorAction(String action, String message) {
    return 'Error $action: $message';
  }

  @override
  String fleetError(String message) {
    return 'Error loading robots: $message';
  }

  @override
  String get fleetEmpty => 'No robots in the fleet yet.';

  @override
  String get fleetAddRobot => 'Add robot';

  @override
  String get fleetStandby => 'Standby';

  @override
  String get fleetCurrentActive => 'In use';

  @override
  String get fleetSwitchToRobot => 'Switch to robot';

  @override
  String get fleetOpenConnectionTooltip => 'Open connection screen';

  @override
  String cameraStreamError(String error) {
    return 'Could not load stream:\n$error';
  }

  @override
  String get cameraRetry => 'Retry';

  @override
  String get waypointsMissionNameTitle => 'Mission name';

  @override
  String get waypointsMissionNew => 'New mission';

  @override
  String get waypointsWaypointLabelTitle => 'Waypoint label';

  @override
  String waypointsWaypointTitle(int n) {
    return 'Waypoint #$n';
  }

  @override
  String get waypointsMissions => 'Missions';

  @override
  String get waypointsNewMissionTooltip => 'New mission';

  @override
  String waypointsWaypointCount(int count) {
    return '$count waypoints';
  }

  @override
  String get waypointsSelectMission =>
      'Select or create a mission in the left panel.';

  @override
  String get waypointsCancelNav => 'Cancel';

  @override
  String get waypointsAddFromPose => 'Add from current pose';

  @override
  String get waypointsRunMission => 'Run mission';

  @override
  String get waypointsDeleteAll => 'Delete all';

  @override
  String get waypointsWaypoint => 'Waypoint';

  @override
  String get waypointsEmptyHint =>
      'No waypoints yet. Drive the robot into position, then tap \"Add from current pose\".';

  @override
  String waypointsSendingMission(int count) {
    return 'Sending mission ($count wp)…';
  }

  @override
  String get waypointsRunning => 'Running…';

  @override
  String waypointsRunningRemaining(int remaining) {
    return 'Running… $remaining wp left';
  }

  @override
  String get mapWaitingMap => 'Waiting for /map …';

  @override
  String get mapTapGoal => 'Tap → Goal';

  @override
  String get mapTapInitPose => 'Tap → Init pose';

  @override
  String get mapRecenterTooltip => 'Recenter';

  @override
  String get mapCancelGoal => 'Cancel goal';

  @override
  String mapInitialPoseSent(String x, String y) {
    return 'Sent initial pose: ($x, $y)';
  }

  @override
  String get mapSendingGoal => 'Sending goal…';

  @override
  String get mapExecuting => 'Executing…';

  @override
  String mapExecutingLeft(String meters) {
    return 'Executing… $meters m left';
  }

  @override
  String mapGoalResult(String status) {
    return 'Result: $status';
  }

  @override
  String get mapCancelling => 'Cancelling…';

  @override
  String get paramsNav2LiveTuning => 'Nav2 live tuning';

  @override
  String get paramsSubtitle =>
      'Each slider/switch sends rcl_interfaces/srv/SetParameters to the matching node.';

  @override
  String get paramsReadCurrent => 'Read current';

  @override
  String paramsNodeLabel(String name) {
    return 'Node: $name';
  }

  @override
  String get paramsReadBackOk => 'Reloaded current parameters from nodes';

  @override
  String paramsReadBackError(String message) {
    return 'Read params error: $message';
  }

  @override
  String paramsSetError(String name, String message) {
    return 'Error $name: $message';
  }

  @override
  String paramsSetStatus(String name, String value, String result) {
    return '$name = $value — $result';
  }

  @override
  String get paramsDescMaxVelX => 'Max DWB tracking linear speed';

  @override
  String get paramsDescInflationGlobal =>
      'Global costmap obstacle inflation radius';

  @override
  String get uiKitSectionOverview => 'Overview';
}
