// ═══════════════════════════════════════════════════════════════
// NOTIFICATION SERVICE
//
// Wraps flutter_local_notifications so the rest of the app only
// needs to call init() once and showAlertNotification() per alert.
//
// REQUIRED NATIVE SETUP:
//   Android — add to android/app/src/main/AndroidManifest.xml:
//     <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
//     <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//
//   iOS — add to ios/Runner/Info.plist:
//     <key>UIBackgroundModes</key>
//     <array><string>fetch</string><string>remote-notification</string></array>
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../domain/models/models.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'autm_alerts';
  static const _channelName = 'AuTOMATO Alerts';
  static const _channelDesc = 'Real-time sensor alert notifications';

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings     = DarwinInitializationSettings(
      requestAlertPermission:     true,
      requestBadgePermission:     true,
      requestSoundPermission:     true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS:     iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Create Android channel with badge/dot support.
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      showBadge: true,
    );
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);
    await androidPlugin?.requestNotificationsPermission();
  }

  /// Updates the iOS app-icon badge count (e.g. 3 unread alerts).
  /// Silently fails on Android or if the plugin version doesn't expose the API.
  static Future<void> updateBadgeCount(int count) async {
    try {
      final iOSPlugin = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iOSPlugin != null) {
        final dynamic d = iOSPlugin;
        await d.setBadgeCount(count);
      }
    } catch (_) {
      // Badge API not available on this platform / plugin version.
    }
  }

  static Future<void> showAlertNotification(AlertRecord alert,
      {int badgeCount = 0}) async {
    final byteData = await rootBundle.load('assets/icon/AUTM-Logo.jpg');
    final logoBytes = byteData.buffer.asUint8List();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance:         Importance.max,
      priority:           Priority.high,
      ticker:             'AuTOMATO Alert',
      largeIcon:            ByteArrayAndroidBitmap(logoBytes),
      styleInformation:     BigTextStyleInformation(
        _bodyFor(alert),
        contentTitle: _titleFor(alert),
        summaryText:  'AuTOMATO Sensor Alert',
      ),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: badgeCount > 0 ? badgeCount : null,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS:     iosDetails,
    );

    await _plugin.show(
      alert.id.hashCode & 0x7FFFFFFF,   // stable positive int ID derived from alert id
      _titleFor(alert),
      _bodyFor(alert),
      details,
      payload: alert.id,
    );
  }

  static String _titleFor(AlertRecord alert) {
    final severity = alert.alertType == SensorStatus.alert ? 'CRITICAL' : 'WARNING';
    return '$severity: ${alert.sensorLabel}';
  }

  static String _bodyFor(AlertRecord alert) {
    final severity = alert.alertType == SensorStatus.alert ? 'critical' : 'warning';
    return '${alert.sensorLabel} is at ${alert.value.toStringAsFixed(2)} ${alert.unit} '
           '— $severity threshold exceeded. Tap to view details.';
  }
}
