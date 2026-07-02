// ═══════════════════════════════════════════════════════════════
// NOTIFICATION SERVICE
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../domain/models/models.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'autm_alerts';
  static const _channelName = 'AuTOMATO Alerts';
  static const _channelDesc = 'Real-time sensor alert notifications';

  // ═══════════════════════════════════════════════════════════════
  // MATCHES pubspec.yaml: android: "launcher_icon"
  // ═══════════════════════════════════════════════════════════════
  static const _notificationIcon = '@mipmap/launcher_icon';

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(_notificationIcon);
    const iosSettings     = DarwinInitializationSettings(
      requestAlertPermission:     true,
      requestBadgePermission:     true,
      requestSoundPermission:     true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS:     iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

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

  static Future<void> updateBadgeCount(int count) async {
    try {
      final iOSPlugin = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iOSPlugin != null) {
        final dynamic d = iOSPlugin;
        await d.setBadgeCount(count);
      }
    } catch (_) {}
  }

  static Future<void> showAlertNotification(AlertRecord alert,
      {int badgeCount = 0}) async {
    Uint8List? logoBytes;
    try {
      final byteData = await rootBundle.load('assets/icon/AUTM-Logo.png');
      logoBytes = byteData.buffer.asUint8List();
    } catch (_) {}

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance:         Importance.max,
      priority:           Priority.high,
      ticker:             'AuTOMATO Alert',
      largeIcon:          logoBytes != null ? ByteArrayAndroidBitmap(logoBytes) : null,
      styleInformation:   BigTextStyleInformation(
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
      alert.id.hashCode & 0x7FFFFFFF,
      _titleFor(alert),
      _bodyFor(alert),
      details,
      payload: jsonEncode({'type': 'alert', 'alertId': alert.id}),
    );
  }

  static Future<void> showDeviceTriggerNotification({
    required String deviceLabel,
    required bool isOn,
    String? reason,
  }) async {
    final title = isOn ? 'System Activated' : 'System Deactivated';
    final body = reason != null
        ? '$deviceLabel turned ${isOn ? "ON" : "OFF"} via $reason.'
        : '$deviceLabel is now ${isOn ? "ON" : "OFF"}.'; 

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'AuTOMATO Automation',
      ),
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      deviceLabel.hashCode & 0x7FFFFFFF,
      title,
      body,
      details,
    );
  }

  static Future<void> showDailyHealthNotification(int percent) async {
    const title = 'AuTOMATO Morning Report';
    final body = 'Greenhouse is $percent% optimal. Tap to view today\'s summary.';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Daily Greenhouse Summary',
      ),
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      'daily_report'.hashCode & 0x7FFFFFFF,
      title,
      body,
      details,
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _handleNotificationTap(data);
    } catch (_) {}
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == 'alert') {
      // Navigate to alert detail
    }
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