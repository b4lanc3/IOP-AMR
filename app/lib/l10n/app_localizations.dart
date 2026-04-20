import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'IOP-AMR Control'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get navCamera;

  /// No description provided for @navLidar.
  ///
  /// In en, this message translates to:
  /// **'LiDAR'**
  String get navLidar;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navMapping.
  ///
  /// In en, this message translates to:
  /// **'Mapping'**
  String get navMapping;

  /// No description provided for @navWaypoints.
  ///
  /// In en, this message translates to:
  /// **'Waypoints'**
  String get navWaypoints;

  /// No description provided for @navMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get navMonitoring;

  /// No description provided for @navParams.
  ///
  /// In en, this message translates to:
  /// **'Params'**
  String get navParams;

  /// No description provided for @navLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get navLogs;

  /// No description provided for @navFleet.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get navFleet;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @shellBrandSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control suite'**
  String get shellBrandSubtitle;

  /// No description provided for @shellDrawerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control & monitoring'**
  String get shellDrawerSubtitle;

  /// No description provided for @shellSwapRobotTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch robot'**
  String get shellSwapRobotTooltip;

  /// No description provided for @shellMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get shellMenuTooltip;

  /// No description provided for @statusNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get statusNotConnected;

  /// No description provided for @statusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get statusOnline;

  /// No description provided for @statusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get statusConnecting;

  /// No description provided for @statusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get statusError;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @estopFabOn.
  ///
  /// In en, this message translates to:
  /// **'E-STOP ON'**
  String get estopFabOn;

  /// No description provided for @estopFab.
  ///
  /// In en, this message translates to:
  /// **'E-STOP'**
  String get estopFab;

  /// No description provided for @estopServiceError.
  ///
  /// In en, this message translates to:
  /// **'E-stop service error: {error}'**
  String estopServiceError(String error);

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsLanguageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get settingsLanguageVietnamese;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsUnits.
  ///
  /// In en, this message translates to:
  /// **'Display units'**
  String get settingsUnits;

  /// No description provided for @settingsUnitsMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric (m, m/s)'**
  String get settingsUnitsMetric;

  /// No description provided for @settingsUnitsImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial (ft, ft/s)'**
  String get settingsUnitsImperial;

  /// No description provided for @settingsLidarGrid.
  ///
  /// In en, this message translates to:
  /// **'Show grid on LiDAR'**
  String get settingsLidarGrid;

  /// No description provided for @settingsSectionConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get settingsSectionConnection;

  /// No description provided for @settingsAutoReconnect.
  ///
  /// In en, this message translates to:
  /// **'Auto-reconnect'**
  String get settingsAutoReconnect;

  /// No description provided for @settingsAutoReconnectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reconnect if rosbridge drops, exponential backoff'**
  String get settingsAutoReconnectSubtitle;

  /// No description provided for @settingsSectionControl.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get settingsSectionControl;

  /// No description provided for @settingsMaxLinear.
  ///
  /// In en, this message translates to:
  /// **'Max linear speed'**
  String get settingsMaxLinear;

  /// No description provided for @settingsMaxAngular.
  ///
  /// In en, this message translates to:
  /// **'Max angular speed'**
  String get settingsMaxAngular;

  /// No description provided for @settingsCmdVelHz.
  ///
  /// In en, this message translates to:
  /// **'/cmd_vel publish rate'**
  String get settingsCmdVelHz;

  /// No description provided for @settingsSectionGamepad.
  ///
  /// In en, this message translates to:
  /// **'Gamepad'**
  String get settingsSectionGamepad;

  /// No description provided for @settingsNewProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get settingsNewProfileTooltip;

  /// No description provided for @settingsEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get settingsEditTooltip;

  /// No description provided for @settingsDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDeleteTooltip;

  /// No description provided for @settingsUsingProfile.
  ///
  /// In en, this message translates to:
  /// **'Active: {name}'**
  String settingsUsingProfile(String name);

  /// No description provided for @settingsSectionApp.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get settingsSectionApp;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsVersionLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get settingsVersionLoading;

  /// No description provided for @settingsWindowsInstall.
  ///
  /// In en, this message translates to:
  /// **'Windows install'**
  String get settingsWindowsInstall;

  /// No description provided for @settingsWindowsInstallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Release: run dart run msix:create in the app folder to build .msix, or use the Release ZIP folder (see scripts/).'**
  String get settingsWindowsInstallSubtitle;

  /// No description provided for @settingsDeleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete profile?'**
  String get settingsDeleteProfileTitle;

  /// No description provided for @settingsDeleteProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String settingsDeleteProfileBody(String name);

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @gamepadEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit gamepad profile'**
  String get gamepadEditTitle;

  /// No description provided for @gamepadProfileName.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get gamepadProfileName;

  /// No description provided for @gamepadLinearAxis.
  ///
  /// In en, this message translates to:
  /// **'Linear axis key (e.g. l.y)'**
  String get gamepadLinearAxis;

  /// No description provided for @gamepadAngularAxis.
  ///
  /// In en, this message translates to:
  /// **'Angular axis key (e.g. r.x)'**
  String get gamepadAngularAxis;

  /// No description provided for @gamepadInvertLinear.
  ///
  /// In en, this message translates to:
  /// **'Invert linear'**
  String get gamepadInvertLinear;

  /// No description provided for @gamepadInvertAngular.
  ///
  /// In en, this message translates to:
  /// **'Invert angular'**
  String get gamepadInvertAngular;

  /// No description provided for @gamepadButtonMap.
  ///
  /// In en, this message translates to:
  /// **'Button mapping'**
  String get gamepadButtonMap;

  /// No description provided for @gamepadLinearScale.
  ///
  /// In en, this message translates to:
  /// **'Linear scale'**
  String get gamepadLinearScale;

  /// No description provided for @gamepadAngularScale.
  ///
  /// In en, this message translates to:
  /// **'Angular scale'**
  String get gamepadAngularScale;

  /// No description provided for @gamepadDeadzone.
  ///
  /// In en, this message translates to:
  /// **'Deadzone'**
  String get gamepadDeadzone;

  /// No description provided for @connectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect robot'**
  String get connectionTitle;

  /// No description provided for @connectionScanMdns.
  ///
  /// In en, this message translates to:
  /// **'Scan mDNS'**
  String get connectionScanMdns;

  /// No description provided for @connectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get connectionSettings;

  /// No description provided for @connectionScanDone.
  ///
  /// In en, this message translates to:
  /// **'Scan complete: {count} robots'**
  String connectionScanDone(int count);

  /// No description provided for @connectionDeleteRobotTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String connectionDeleteRobotTitle(String name);

  /// No description provided for @connectionDeleteRobotBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get connectionDeleteRobotBody;

  /// No description provided for @connectionFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to {name} — retrying…'**
  String connectionFailedRetry(String name);

  /// No description provided for @connectionHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Fleet & connection'**
  String get connectionHeroTitle;

  /// No description provided for @connectionHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a robot to work with, or add an IP manually / scan mDNS. After rosbridge connects, this device remembers the profile.'**
  String get connectionHeroSubtitle;

  /// No description provided for @connectionRobotsSaved.
  ///
  /// In en, this message translates to:
  /// **'{count} robots saved'**
  String connectionRobotsSaved(int count);

  /// No description provided for @connectionRosbridgeChip.
  ///
  /// In en, this message translates to:
  /// **'rosbridge 9090 · video 8080'**
  String get connectionRosbridgeChip;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String connectionError(String message);

  /// No description provided for @connectionAddIp.
  ///
  /// In en, this message translates to:
  /// **'Add IP'**
  String get connectionAddIp;

  /// No description provided for @connectionPingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Test ping'**
  String get connectionPingTooltip;

  /// No description provided for @connectionEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get connectionEditTooltip;

  /// No description provided for @connectionDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get connectionDeleteTooltip;

  /// No description provided for @connectionConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectionConnect;

  /// No description provided for @connectionPingUnreachable.
  ///
  /// In en, this message translates to:
  /// **'unreachable'**
  String get connectionPingUnreachable;

  /// No description provided for @connectionNamespacePill.
  ///
  /// In en, this message translates to:
  /// **'ns {value}'**
  String connectionNamespacePill(String value);

  /// No description provided for @connectionVideoPill.
  ///
  /// In en, this message translates to:
  /// **'video {port}'**
  String connectionVideoPill(int port);

  /// No description provided for @connectionPingPill.
  ///
  /// In en, this message translates to:
  /// **'ping {result}'**
  String connectionPingPill(String result);

  /// No description provided for @connectionNetworkHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Network & robots: LAN, Tailscale, remote'**
  String get connectionNetworkHelpTitle;

  /// No description provided for @connectionNetworkHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When to use LAN IP vs 100.x…'**
  String get connectionNetworkHelpSubtitle;

  /// No description provided for @connectionHintLanTitle.
  ///
  /// In en, this message translates to:
  /// **'Same Wi‑Fi / LAN (often no Internet needed)'**
  String get connectionHintLanTitle;

  /// No description provided for @connectionHintLanBody.
  ///
  /// In en, this message translates to:
  /// **'PC and Jetson on the same switch/Wi‑Fi: use the robot’s LAN IP (e.g. 192.168.x.x). Ensure rosbridge listens on 0.0.0.0:9090 on Jetson. No Tailscale required.'**
  String get connectionHintLanBody;

  /// No description provided for @connectionHintTailscaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Tailscale (100.x.x.x — e.g. preset DDE-AMR)'**
  String get connectionHintTailscaleTitle;

  /// No description provided for @connectionHintTailscaleBody.
  ///
  /// In en, this message translates to:
  /// **'Both machines on the same tailnet: connect via the Tailscale IP assigned to Jetson. Use when laptop and robot differ subnet or are remote. For same room “offline” work, prefer LAN over 100.x.'**
  String get connectionHintTailscaleBody;

  /// No description provided for @connectionHintNotTailscaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Not on the same Tailscale'**
  String get connectionHintNotTailscaleTitle;

  /// No description provided for @connectionHintNotTailscaleBody.
  ///
  /// In en, this message translates to:
  /// **'Join the same tailnet, or use another VPN (WireGuard, ZeroTier…), or expose rosbridge through your router (NAT + security). In the app: add a profile with the right IP/port.'**
  String get connectionHintNotTailscaleBody;

  /// No description provided for @connectionEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No robots yet'**
  String get connectionEmptyTitle;

  /// No description provided for @connectionEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add the Jetson IP (rosbridge is usually port 9090) or scan mDNS if the robot advertises on the LAN.'**
  String get connectionEmptyBody;

  /// No description provided for @connectionTipAddIp.
  ///
  /// In en, this message translates to:
  /// **'Add IP — enter host, port, namespace'**
  String get connectionTipAddIp;

  /// No description provided for @connectionTipMdns.
  ///
  /// In en, this message translates to:
  /// **'Scan mDNS — find robots on the local network'**
  String get connectionTipMdns;

  /// No description provided for @connectionDialogEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit robot'**
  String get connectionDialogEditTitle;

  /// No description provided for @connectionDialogAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add robot'**
  String get connectionDialogAddTitle;

  /// No description provided for @connectionDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get connectionDisplayName;

  /// No description provided for @connectionHost.
  ///
  /// In en, this message translates to:
  /// **'IP / hostname'**
  String get connectionHost;

  /// No description provided for @connectionRosbridgePort.
  ///
  /// In en, this message translates to:
  /// **'rosbridge port'**
  String get connectionRosbridgePort;

  /// No description provided for @connectionVideoPort.
  ///
  /// In en, this message translates to:
  /// **'video port'**
  String get connectionVideoPort;

  /// No description provided for @connectionNamespaceOptional.
  ///
  /// In en, this message translates to:
  /// **'Namespace (optional)'**
  String get connectionNamespaceOptional;

  /// No description provided for @connectionNamespaceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. /robot_1'**
  String get connectionNamespaceHint;

  /// No description provided for @connectionAuthTokenOptional.
  ///
  /// In en, this message translates to:
  /// **'Auth token (optional)'**
  String get connectionAuthTokenOptional;

  /// No description provided for @connectionUseWss.
  ///
  /// In en, this message translates to:
  /// **'Use wss:// / https://'**
  String get connectionUseWss;

  /// No description provided for @connectionNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get connectionNameRequired;

  /// No description provided for @connectionHostRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter host'**
  String get connectionHostRequired;

  /// No description provided for @dashboardNoRobot.
  ///
  /// In en, this message translates to:
  /// **'No robot selected'**
  String get dashboardNoRobot;

  /// No description provided for @dashboardLiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Live status'**
  String get dashboardLiveStatus;

  /// No description provided for @dashboardLiveStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Data from rosbridge topics (battery, velocity, pose, CPU/GPU).'**
  String get dashboardLiveStatusSubtitle;

  /// No description provided for @dashboardOnlineHost.
  ///
  /// In en, this message translates to:
  /// **'Online · {host}'**
  String dashboardOnlineHost(String host);

  /// No description provided for @dashboardOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Offline — check rosbridge or pick another robot'**
  String get dashboardOfflineHint;

  /// No description provided for @dashboardBatteryPercent.
  ///
  /// In en, this message translates to:
  /// **'{pct}% battery'**
  String dashboardBatteryPercent(String pct);

  /// No description provided for @dashboardBatteryCharging.
  ///
  /// In en, this message translates to:
  /// **'charging'**
  String get dashboardBatteryCharging;

  /// No description provided for @dashboardBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get dashboardBattery;

  /// No description provided for @dashboardVelocity.
  ///
  /// In en, this message translates to:
  /// **'Velocity'**
  String get dashboardVelocity;

  /// No description provided for @dashboardVelocityOmega.
  ///
  /// In en, this message translates to:
  /// **'ω: {value} rad/s'**
  String dashboardVelocityOmega(String value);

  /// No description provided for @dashboardPoseOdom.
  ///
  /// In en, this message translates to:
  /// **'odom'**
  String get dashboardPoseOdom;

  /// No description provided for @dashboardPoseAmcl.
  ///
  /// In en, this message translates to:
  /// **'amcl (map)'**
  String get dashboardPoseAmcl;

  /// No description provided for @dashboardPoseTitle.
  ///
  /// In en, this message translates to:
  /// **'Pose'**
  String get dashboardPoseTitle;

  /// No description provided for @dashboardSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get dashboardSystemTitle;

  /// No description provided for @cameraNoRobot.
  ///
  /// In en, this message translates to:
  /// **'No robot selected'**
  String get cameraNoRobot;

  /// No description provided for @cameraRgbTopic.
  ///
  /// In en, this message translates to:
  /// **'RGB topic'**
  String get cameraRgbTopic;

  /// No description provided for @cameraDepthTopic.
  ///
  /// In en, this message translates to:
  /// **'Depth topic'**
  String get cameraDepthTopic;

  /// No description provided for @cameraReloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reload both streams'**
  String get cameraReloadTooltip;

  /// No description provided for @cameraTabRgb.
  ///
  /// In en, this message translates to:
  /// **'RGB'**
  String get cameraTabRgb;

  /// No description provided for @cameraTabDepth.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get cameraTabDepth;

  /// No description provided for @lidarRange.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get lidarRange;

  /// No description provided for @lidarResetView.
  ///
  /// In en, this message translates to:
  /// **'Reset view'**
  String get lidarResetView;

  /// No description provided for @lidarScaleLabel.
  ///
  /// In en, this message translates to:
  /// **'{value} px/m'**
  String lidarScaleLabel(String value);

  /// No description provided for @mappingTitle.
  ///
  /// In en, this message translates to:
  /// **'SLAM Mapping'**
  String get mappingTitle;

  /// No description provided for @mappingRunning.
  ///
  /// In en, this message translates to:
  /// **'Mapping'**
  String get mappingRunning;

  /// No description provided for @mappingMapName.
  ///
  /// In en, this message translates to:
  /// **'Map name'**
  String get mappingMapName;

  /// No description provided for @mappingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get mappingStart;

  /// No description provided for @mappingStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get mappingStop;

  /// No description provided for @mappingSaveMap.
  ///
  /// In en, this message translates to:
  /// **'Save map'**
  String get mappingSaveMap;

  /// No description provided for @mappingReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get mappingReset;

  /// No description provided for @mappingOpenMap.
  ///
  /// In en, this message translates to:
  /// **'View live on Map'**
  String get mappingOpenMap;

  /// No description provided for @mappingSlamResult.
  ///
  /// In en, this message translates to:
  /// **'SLAM {action}: {message}'**
  String mappingSlamResult(String action, String message);

  /// No description provided for @mappingError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String mappingError(String message);

  /// No description provided for @mappingSaveRequested.
  ///
  /// In en, this message translates to:
  /// **'Save requested for map \"{name}\"'**
  String mappingSaveRequested(String name);

  /// No description provided for @mappingSaveError.
  ///
  /// In en, this message translates to:
  /// **'Save error: {message}'**
  String mappingSaveError(String message);

  /// No description provided for @mappingHowToTitle.
  ///
  /// In en, this message translates to:
  /// **'Mapping workflow'**
  String get mappingHowToTitle;

  /// No description provided for @mappingHowToBody.
  ///
  /// In en, this message translates to:
  /// **'1. Tap Start to run slam_toolbox.\n2. Open Map or Teleop and drive slowly around the area.\n3. When the map looks good, return here and tap Save map.\n4. After saving, you can Stop SLAM and switch to navigation mode.'**
  String get mappingHowToBody;

  /// No description provided for @logsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rosbag recorder'**
  String get logsTitle;

  /// No description provided for @logsBagName.
  ///
  /// In en, this message translates to:
  /// **'Bag name'**
  String get logsBagName;

  /// No description provided for @logsTopicsComma.
  ///
  /// In en, this message translates to:
  /// **'Topics (comma-separated)'**
  String get logsTopicsComma;

  /// No description provided for @logsStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get logsStart;

  /// No description provided for @logsStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get logsStop;

  /// No description provided for @logsRefreshList.
  ///
  /// In en, this message translates to:
  /// **'Refresh list'**
  String get logsRefreshList;

  /// No description provided for @logsAvailableBags.
  ///
  /// In en, this message translates to:
  /// **'Available bags'**
  String get logsAvailableBags;

  /// No description provided for @logsBagCount.
  ///
  /// In en, this message translates to:
  /// **'{count} bags'**
  String logsBagCount(int count);

  /// No description provided for @logsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bags yet. Tap \"Refresh list\" or record a new bag.'**
  String get logsEmpty;

  /// No description provided for @logsNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected to robot'**
  String get logsNotConnected;

  /// No description provided for @logsBagAction.
  ///
  /// In en, this message translates to:
  /// **'Bag {action}: {message}'**
  String logsBagAction(String action, String message);

  /// No description provided for @logsErrorAction.
  ///
  /// In en, this message translates to:
  /// **'Error {action}: {message}'**
  String logsErrorAction(String action, String message);

  /// No description provided for @fleetError.
  ///
  /// In en, this message translates to:
  /// **'Error loading robots: {message}'**
  String fleetError(String message);

  /// No description provided for @fleetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No robots in the fleet yet.'**
  String get fleetEmpty;

  /// No description provided for @fleetAddRobot.
  ///
  /// In en, this message translates to:
  /// **'Add robot'**
  String get fleetAddRobot;

  /// No description provided for @fleetStandby.
  ///
  /// In en, this message translates to:
  /// **'Standby'**
  String get fleetStandby;

  /// No description provided for @fleetCurrentActive.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get fleetCurrentActive;

  /// No description provided for @fleetSwitchToRobot.
  ///
  /// In en, this message translates to:
  /// **'Switch to robot'**
  String get fleetSwitchToRobot;

  /// No description provided for @fleetOpenConnectionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open connection screen'**
  String get fleetOpenConnectionTooltip;

  /// No description provided for @cameraStreamError.
  ///
  /// In en, this message translates to:
  /// **'Could not load stream:\n{error}'**
  String cameraStreamError(String error);

  /// No description provided for @cameraRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get cameraRetry;

  /// No description provided for @waypointsMissionNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Mission name'**
  String get waypointsMissionNameTitle;

  /// No description provided for @waypointsMissionNew.
  ///
  /// In en, this message translates to:
  /// **'New mission'**
  String get waypointsMissionNew;

  /// No description provided for @waypointsWaypointLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Waypoint label'**
  String get waypointsWaypointLabelTitle;

  /// No description provided for @waypointsWaypointTitle.
  ///
  /// In en, this message translates to:
  /// **'Waypoint #{n}'**
  String waypointsWaypointTitle(int n);

  /// No description provided for @waypointsMissions.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get waypointsMissions;

  /// No description provided for @waypointsNewMissionTooltip.
  ///
  /// In en, this message translates to:
  /// **'New mission'**
  String get waypointsNewMissionTooltip;

  /// No description provided for @waypointsWaypointCount.
  ///
  /// In en, this message translates to:
  /// **'{count} waypoints'**
  String waypointsWaypointCount(int count);

  /// No description provided for @waypointsSelectMission.
  ///
  /// In en, this message translates to:
  /// **'Select or create a mission in the left panel.'**
  String get waypointsSelectMission;

  /// No description provided for @waypointsCancelNav.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get waypointsCancelNav;

  /// No description provided for @waypointsAddFromPose.
  ///
  /// In en, this message translates to:
  /// **'Add from current pose'**
  String get waypointsAddFromPose;

  /// No description provided for @waypointsRunMission.
  ///
  /// In en, this message translates to:
  /// **'Run mission'**
  String get waypointsRunMission;

  /// No description provided for @waypointsDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get waypointsDeleteAll;

  /// No description provided for @waypointsWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Waypoint'**
  String get waypointsWaypoint;

  /// No description provided for @waypointsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No waypoints yet. Drive the robot into position, then tap \"Add from current pose\".'**
  String get waypointsEmptyHint;

  /// No description provided for @waypointsSendingMission.
  ///
  /// In en, this message translates to:
  /// **'Sending mission ({count} wp)…'**
  String waypointsSendingMission(int count);

  /// No description provided for @waypointsRunning.
  ///
  /// In en, this message translates to:
  /// **'Running…'**
  String get waypointsRunning;

  /// No description provided for @waypointsRunningRemaining.
  ///
  /// In en, this message translates to:
  /// **'Running… {remaining} wp left'**
  String waypointsRunningRemaining(int remaining);

  /// No description provided for @mapWaitingMap.
  ///
  /// In en, this message translates to:
  /// **'Waiting for /map …'**
  String get mapWaitingMap;

  /// No description provided for @mapTapGoal.
  ///
  /// In en, this message translates to:
  /// **'Tap → Goal'**
  String get mapTapGoal;

  /// No description provided for @mapTapInitPose.
  ///
  /// In en, this message translates to:
  /// **'Tap → Init pose'**
  String get mapTapInitPose;

  /// No description provided for @mapRecenterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Recenter'**
  String get mapRecenterTooltip;

  /// No description provided for @mapCancelGoal.
  ///
  /// In en, this message translates to:
  /// **'Cancel goal'**
  String get mapCancelGoal;

  /// No description provided for @mapInitialPoseSent.
  ///
  /// In en, this message translates to:
  /// **'Sent initial pose: ({x}, {y})'**
  String mapInitialPoseSent(String x, String y);

  /// No description provided for @mapSendingGoal.
  ///
  /// In en, this message translates to:
  /// **'Sending goal…'**
  String get mapSendingGoal;

  /// No description provided for @mapExecuting.
  ///
  /// In en, this message translates to:
  /// **'Executing…'**
  String get mapExecuting;

  /// No description provided for @mapExecutingLeft.
  ///
  /// In en, this message translates to:
  /// **'Executing… {meters} m left'**
  String mapExecutingLeft(String meters);

  /// No description provided for @mapGoalResult.
  ///
  /// In en, this message translates to:
  /// **'Result: {status}'**
  String mapGoalResult(String status);

  /// No description provided for @mapCancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get mapCancelling;

  /// No description provided for @paramsNav2LiveTuning.
  ///
  /// In en, this message translates to:
  /// **'Nav2 live tuning'**
  String get paramsNav2LiveTuning;

  /// No description provided for @paramsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Each slider/switch sends rcl_interfaces/srv/SetParameters to the matching node.'**
  String get paramsSubtitle;

  /// No description provided for @paramsReadCurrent.
  ///
  /// In en, this message translates to:
  /// **'Read current'**
  String get paramsReadCurrent;

  /// No description provided for @paramsNodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Node: {name}'**
  String paramsNodeLabel(String name);

  /// No description provided for @paramsReadBackOk.
  ///
  /// In en, this message translates to:
  /// **'Reloaded current parameters from nodes'**
  String get paramsReadBackOk;

  /// No description provided for @paramsReadBackError.
  ///
  /// In en, this message translates to:
  /// **'Read params error: {message}'**
  String paramsReadBackError(String message);

  /// No description provided for @paramsSetError.
  ///
  /// In en, this message translates to:
  /// **'Error {name}: {message}'**
  String paramsSetError(String name, String message);

  /// No description provided for @paramsSetStatus.
  ///
  /// In en, this message translates to:
  /// **'{name} = {value} — {result}'**
  String paramsSetStatus(String name, String value, String result);

  /// No description provided for @paramsDescMaxVelX.
  ///
  /// In en, this message translates to:
  /// **'Max DWB tracking linear speed'**
  String get paramsDescMaxVelX;

  /// No description provided for @paramsDescInflationGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global costmap obstacle inflation radius'**
  String get paramsDescInflationGlobal;

  /// No description provided for @uiKitSectionOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get uiKitSectionOverview;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
