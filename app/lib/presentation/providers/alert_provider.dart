import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/sensor_data.dart';
import '../../domain/repositories/repositories.dart';
import '../../services/notification_service.dart';

class AlertProvider extends ChangeNotifier {
  final AlertRepository _alertRepo;
  StreamSubscription<List<AlertRecord>>? _sub;

  List<AlertRecord> _alerts = [];
  final Map<String, DateTime> _lastNotifiedAt = {};

  AlertProvider({
    required AlertRepository alertRepo,
  }) : _alertRepo = alertRepo {
    _sub = _alertRepo.alertStream.listen((a) async {
      final previousIds = _alerts.map((x) => x.id).toSet();
      _alerts = a;
      notifyListeners();

      final now = DateTime.now();
      const renotifyInterval = Duration(minutes: 2);

      final activeCount = a.where((alert) => !alert.isResolved).length;
      await NotificationService.updateBadgeCount(activeCount);

      for (final alert in a) {
        if (alert.isResolved) continue;

        final last = _lastNotifiedAt[alert.id];
        final isNew = !previousIds.contains(alert.id);
        final shouldReNotify =
            last != null && now.difference(last) >= renotifyInterval;

        if (isNew || shouldReNotify) {
          _lastNotifiedAt[alert.id] = now;
          try {
            await NotificationService.showAlertNotification(
              alert,
              badgeCount: activeCount,
            );
          } catch (e) {
            debugPrint('Notification error: $e');
          }
        }
      }

      _lastNotifiedAt.removeWhere(
        (id, _) =>
            !a.any((alert) => alert.id == id) ||
            a.any((alert) => alert.id == id && alert.isResolved),
      );
    });
  }

  List<AlertRecord> get allAlerts => _alerts;
  List<AlertRecord> get activeAlerts =>
      _alerts.where((a) => !a.isResolved).toList();
  int get alertCount => activeAlerts.length;

  @override
  void dispose() {
    _sub?.cancel();
    _alertRepo.dispose();
    super.dispose();
  }
}
