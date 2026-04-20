// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'IOP-AMR Control';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navCamera => 'Camera';

  @override
  String get navLidar => 'LiDAR';

  @override
  String get navMap => 'Bản đồ';

  @override
  String get navMapping => 'Mapping';

  @override
  String get navWaypoints => 'Waypoint';

  @override
  String get navMonitoring => 'Giám sát';

  @override
  String get navParams => 'Tham số';

  @override
  String get navLogs => 'Logs';

  @override
  String get navFleet => 'Fleet';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get shellBrandSubtitle => 'Bộ điều khiển';

  @override
  String get shellDrawerSubtitle => 'Điều khiển & giám sát';

  @override
  String get shellSwapRobotTooltip => 'Đổi robot';

  @override
  String get shellMenuTooltip => 'Menu';

  @override
  String get statusNotConnected => 'Chưa kết nối';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusConnecting => 'Đang nối…';

  @override
  String get statusError => 'Lỗi';

  @override
  String get statusOffline => 'Offline';

  @override
  String get estopFabOn => 'E-STOP BẬT';

  @override
  String get estopFab => 'E-STOP';

  @override
  String estopServiceError(String error) {
    return 'Lỗi dịch vụ E-stop: $error';
  }

  @override
  String get settingsSectionAppearance => 'Giao diện';

  @override
  String get settingsSectionLanguage => 'Ngôn ngữ';

  @override
  String get settingsLanguageLabel => 'Ngôn ngữ giao diện';

  @override
  String get settingsLanguageVietnamese => 'Tiếng Việt';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsTheme => 'Chủ đề';

  @override
  String get settingsThemeSystem => 'Theo hệ thống';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsUnits => 'Đơn vị hiển thị';

  @override
  String get settingsUnitsMetric => 'Metric (m, m/s)';

  @override
  String get settingsUnitsImperial => 'Imperial (ft, ft/s)';

  @override
  String get settingsLidarGrid => 'Hiện lưới trên LiDAR';

  @override
  String get settingsSectionConnection => 'Kết nối';

  @override
  String get settingsAutoReconnect => 'Auto-reconnect';

  @override
  String get settingsAutoReconnectSubtitle =>
      'Tự kết nối lại nếu rosbridge rớt, exponential backoff';

  @override
  String get settingsSectionControl => 'Điều khiển';

  @override
  String get settingsMaxLinear => 'Tốc độ tuyến tính tối đa';

  @override
  String get settingsMaxAngular => 'Tốc độ quay tối đa';

  @override
  String get settingsCmdVelHz => 'Tần số publish /cmd_vel';

  @override
  String get settingsSectionGamepad => 'Gamepad';

  @override
  String get settingsNewProfileTooltip => 'Tạo profile mới';

  @override
  String get settingsEditTooltip => 'Sửa';

  @override
  String get settingsDeleteTooltip => 'Xoá';

  @override
  String settingsUsingProfile(String name) {
    return 'Đang dùng: $name';
  }

  @override
  String get settingsSectionApp => 'Ứng dụng';

  @override
  String get settingsVersion => 'Phiên bản';

  @override
  String get settingsVersionLoading => 'Đang tải…';

  @override
  String get settingsWindowsInstall => 'Cài đặt Windows';

  @override
  String get settingsWindowsInstallSubtitle =>
      'Bản phát hành: chạy dart run msix:create trong thư mục app để tạo file .msix, hoặc dùng ZIP thư mục Release (xem scripts/).';

  @override
  String get settingsDeleteProfileTitle => 'Xoá profile?';

  @override
  String settingsDeleteProfileBody(String name) {
    return 'Xoá \"$name\"? Không thể khôi phục.';
  }

  @override
  String get commonCancel => 'Huỷ';

  @override
  String get commonDelete => 'Xoá';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonOk => 'OK';

  @override
  String get gamepadEditTitle => 'Sửa gamepad profile';

  @override
  String get gamepadProfileName => 'Tên profile';

  @override
  String get gamepadLinearAxis => 'Linear axis key (vd. l.y)';

  @override
  String get gamepadAngularAxis => 'Angular axis key (vd. r.x)';

  @override
  String get gamepadInvertLinear => 'Invert linear';

  @override
  String get gamepadInvertAngular => 'Invert angular';

  @override
  String get gamepadButtonMap => 'Map nút bấm';

  @override
  String get gamepadLinearScale => 'Tỉ lệ linear';

  @override
  String get gamepadAngularScale => 'Tỉ lệ angular';

  @override
  String get gamepadDeadzone => 'Deadzone';

  @override
  String get connectionTitle => 'Kết nối robot';

  @override
  String get connectionScanMdns => 'Quét mDNS';

  @override
  String get connectionSettings => 'Cài đặt';

  @override
  String connectionScanDone(int count) {
    return 'Quét xong: $count robot';
  }

  @override
  String connectionDeleteRobotTitle(String name) {
    return 'Xoá \"$name\"?';
  }

  @override
  String get connectionDeleteRobotBody => 'Thao tác này không thể hoàn tác.';

  @override
  String connectionFailedRetry(String name) {
    return 'Không kết nối được $name — đang tự retry…';
  }

  @override
  String get connectionHeroTitle => 'Fleet & kết nối';

  @override
  String get connectionHeroSubtitle =>
      'Chọn robot để làm việc, hoặc thêm IP thủ công / quét mDNS. Sau khi nối rosbridge, app sẽ nhớ profile trên máy này.';

  @override
  String connectionRobotsSaved(int count) {
    return '$count robot đã lưu';
  }

  @override
  String get connectionRosbridgeChip => 'rosbridge 9090 · video 8080';

  @override
  String connectionError(String message) {
    return 'Lỗi: $message';
  }

  @override
  String get connectionAddIp => 'Thêm IP';

  @override
  String get connectionPingTooltip => 'Test ping';

  @override
  String get connectionEditTooltip => 'Sửa';

  @override
  String get connectionDeleteTooltip => 'Xoá';

  @override
  String get connectionConnect => 'Kết nối';

  @override
  String get connectionPingUnreachable => 'không reach';

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
      'Mạng & robot: LAN, Tailscale, máy khác';

  @override
  String get connectionNetworkHelpSubtitle =>
      'Khi nào dùng IP LAN, khi nào dùng 100.x…';

  @override
  String get connectionHintLanTitle =>
      'Cùng Wi‑Fi / LAN (thường không cần Internet)';

  @override
  String get connectionHintLanBody =>
      'PC và Jetson cùng switch/Wi‑Fi: dùng IP mạng nội bộ của robot (vd. 192.168.x.x). Đảm bảo rosbridge lắng nghe 0.0.0.0:9090 trên Jetson. Cách này không phụ thuộc Tailscale.';

  @override
  String get connectionHintTailscaleTitle =>
      'Tailscale (IP 100.x.x.x — ví dụ DDE-AMR đặt sẵn)';

  @override
  String get connectionHintTailscaleBody =>
      'Hai máy cùng tailnet: kết nối qua IP Tailscale được gán cho Jetson. Phù hợp khi laptop và robot khác subnet hoặc ở xa. Nếu bạn muốn làm việc “offline” nhưng vẫn cùng phòng: ưu tiên IP LAN thay vì 100.x.';

  @override
  String get connectionHintNotTailscaleTitle => 'Không cùng Tailscale';

  @override
  String get connectionHintNotTailscaleBody =>
      'Gắn máy vào cùng tailnet, hoặc dùng VPN khác (WireGuard, ZeroTier…), hoặc mở cổng rosbridge qua router (NAT + bảo mật). Trong app: thêm profile mới với IP/port tương ứng.';

  @override
  String get connectionEmptyTitle => 'Chưa có robot';

  @override
  String get connectionEmptyBody =>
      'Thêm địa chỉ IP Jetson (rosbridge thường là cổng 9090) hoặc quét mDNS nếu robot quảng bá trên LAN.';

  @override
  String get connectionTipAddIp => 'Nút Thêm IP — nhập host, port, namespace';

  @override
  String get connectionTipMdns => 'Quét mDNS — tìm robot trên mạng cục bộ';

  @override
  String get connectionDialogEditTitle => 'Sửa robot';

  @override
  String get connectionDialogAddTitle => 'Thêm robot';

  @override
  String get connectionDisplayName => 'Tên hiển thị';

  @override
  String get connectionHost => 'IP / hostname';

  @override
  String get connectionRosbridgePort => 'rosbridge port';

  @override
  String get connectionVideoPort => 'video port';

  @override
  String get connectionNamespaceOptional => 'Namespace (optional)';

  @override
  String get connectionNamespaceHint => 'vd: /robot_1';

  @override
  String get connectionAuthTokenOptional => 'Auth token (optional)';

  @override
  String get connectionUseWss => 'Dùng wss:// / https://';

  @override
  String get connectionNameRequired => 'Nhập tên';

  @override
  String get connectionHostRequired => 'Nhập host';

  @override
  String get dashboardNoRobot => 'Chưa chọn robot';

  @override
  String get dashboardLiveStatus => 'Trạng thái trực tiếp';

  @override
  String get dashboardLiveStatusSubtitle =>
      'Dữ liệu cập nhật theo topic rosbridge (pin, vận tốc, pose, CPU/GPU).';

  @override
  String dashboardOnlineHost(String host) {
    return 'Đang trực tuyến · $host';
  }

  @override
  String get dashboardOfflineHint =>
      'Offline — kiểm tra rosbridge hoặc chọn robot khác';

  @override
  String dashboardBatteryPercent(String pct) {
    return '$pct% pin';
  }

  @override
  String get dashboardBatteryCharging => 'đang sạc';

  @override
  String get dashboardBattery => 'Pin';

  @override
  String get dashboardVelocity => 'Vận tốc';

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
  String get dashboardSystemTitle => 'Hệ thống';

  @override
  String get cameraNoRobot => 'Chưa chọn robot';

  @override
  String get cameraRgbTopic => 'RGB topic';

  @override
  String get cameraDepthTopic => 'Depth topic';

  @override
  String get cameraReloadTooltip => 'Reload cả hai stream';

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
  String get mappingRunning => 'Đang mapping';

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
  String get mappingOpenMap => 'Xem real-time ở Map';

  @override
  String mappingSlamResult(String action, String message) {
    return 'SLAM $action: $message';
  }

  @override
  String mappingError(String message) {
    return 'Lỗi: $message';
  }

  @override
  String mappingSaveRequested(String name) {
    return 'Đã yêu cầu lưu map \"$name\"';
  }

  @override
  String mappingSaveError(String message) {
    return 'Save lỗi: $message';
  }

  @override
  String get mappingHowToTitle => 'Quy trình quét bản đồ';

  @override
  String get mappingHowToBody =>
      '1. Bấm Start để chạy slam_toolbox.\n2. Sang tab Map hoặc Teleop, lái robot đi chậm quanh khu vực.\n3. Khi thấy map đủ chi tiết, quay lại đây và bấm Save map.\n4. Sau khi save, có thể Stop để tắt SLAM → chuyển sang chế độ navigation.';

  @override
  String get logsTitle => 'Rosbag recorder';

  @override
  String get logsBagName => 'Bag name';

  @override
  String get logsTopicsComma => 'Topics (ngăn cách bằng dấu phẩy)';

  @override
  String get logsStart => 'Start';

  @override
  String get logsStop => 'Stop';

  @override
  String get logsRefreshList => 'Refresh list';

  @override
  String get logsAvailableBags => 'Bags có sẵn';

  @override
  String logsBagCount(int count) {
    return '$count bag';
  }

  @override
  String get logsEmpty =>
      'Chưa có bag nào. Bấm \"Refresh list\" hoặc ghi bag mới.';

  @override
  String get logsNotConnected => 'Chưa kết nối robot';

  @override
  String logsBagAction(String action, String message) {
    return 'Bag $action: $message';
  }

  @override
  String logsErrorAction(String action, String message) {
    return 'Lỗi $action: $message';
  }

  @override
  String fleetError(String message) {
    return 'Lỗi load robots: $message';
  }

  @override
  String get fleetEmpty => 'Chưa có robot nào trong fleet.';

  @override
  String get fleetAddRobot => 'Thêm robot';

  @override
  String get fleetStandby => 'Standby';

  @override
  String get fleetCurrentActive => 'Đang active';

  @override
  String get fleetSwitchToRobot => 'Chuyển sang robot';

  @override
  String get fleetOpenConnectionTooltip => 'Mở connection screen';

  @override
  String cameraStreamError(String error) {
    return 'Không lấy được stream:\n$error';
  }

  @override
  String get cameraRetry => 'Thử lại';

  @override
  String get waypointsMissionNameTitle => 'Tên mission';

  @override
  String get waypointsMissionNew => 'Mission mới';

  @override
  String get waypointsWaypointLabelTitle => 'Label waypoint';

  @override
  String waypointsWaypointTitle(int n) {
    return 'Waypoint #$n';
  }

  @override
  String get waypointsMissions => 'Missions';

  @override
  String get waypointsNewMissionTooltip => 'Tạo mission';

  @override
  String waypointsWaypointCount(int count) {
    return '$count waypoint';
  }

  @override
  String get waypointsSelectMission =>
      'Chọn hoặc tạo mission ở panel bên trái.';

  @override
  String get waypointsCancelNav => 'Cancel';

  @override
  String get waypointsAddFromPose => 'Thêm từ pose hiện tại';

  @override
  String get waypointsRunMission => 'Run mission';

  @override
  String get waypointsDeleteAll => 'Xoá tất cả';

  @override
  String get waypointsWaypoint => 'Waypoint';

  @override
  String get waypointsEmptyHint =>
      'Chưa có waypoint. Lái robot tới vị trí rồi bấm \"Thêm từ pose hiện tại\".';

  @override
  String waypointsSendingMission(int count) {
    return 'Đang gửi mission ($count wp)…';
  }

  @override
  String get waypointsRunning => 'Đang chạy…';

  @override
  String waypointsRunningRemaining(int remaining) {
    return 'Đang chạy… còn $remaining wp';
  }

  @override
  String get mapWaitingMap => 'Đang chờ /map …';

  @override
  String get mapTapGoal => 'Tap → Goal';

  @override
  String get mapTapInitPose => 'Tap → InitPose';

  @override
  String get mapRecenterTooltip => 'Recenter';

  @override
  String get mapCancelGoal => 'Cancel goal';

  @override
  String mapInitialPoseSent(String x, String y) {
    return 'Gửi initialpose: ($x, $y)';
  }

  @override
  String get mapSendingGoal => 'Đang gửi goal…';

  @override
  String get mapExecuting => 'Đang thực hiện…';

  @override
  String mapExecutingLeft(String meters) {
    return 'Đang thực hiện… còn $meters m';
  }

  @override
  String mapGoalResult(String status) {
    return 'Kết quả: $status';
  }

  @override
  String get mapCancelling => 'Đang huỷ…';

  @override
  String get paramsNav2LiveTuning => 'Nav2 live tuning';

  @override
  String get paramsSubtitle =>
      'Mỗi lần nhả slider/switch sẽ gửi rcl_interfaces/srv/SetParameters tới node tương ứng.';

  @override
  String get paramsReadCurrent => 'Read current';

  @override
  String paramsNodeLabel(String name) {
    return 'Node: $name';
  }

  @override
  String get paramsReadBackOk => 'Đã đọc lại tham số hiện tại từ node';

  @override
  String paramsReadBackError(String message) {
    return 'Đọc param lỗi: $message';
  }

  @override
  String paramsSetError(String name, String message) {
    return 'Lỗi $name: $message';
  }

  @override
  String paramsSetStatus(String name, String value, String result) {
    return '$name = $value — $result';
  }

  @override
  String get paramsDescMaxVelX => 'Tốc độ tối đa của DWB khi bám đường';

  @override
  String get paramsDescInflationGlobal =>
      'Bán kính \"thổi phồng\" chướng ngại cho planner toàn cục';

  @override
  String get uiKitSectionOverview => 'Tổng quan';
}
