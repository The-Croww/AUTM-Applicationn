import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/sensor_data.dart';
import '../../domain/repositories/repositories.dart';
import '../../services/notification_service.dart';

class AppState extends ChangeNotifier {
  final SensorRepository _sensorRepo;
  final DeviceRepository _deviceRepo;
  final AlertRepository  _alertRepo;
  final SystemRepository _systemRepo;
  final CameraRepository _cameraRepo;

  List<SensorReading> _readings = [];
  List<DeviceState>   _devices  = [];
  List<AlertRecord>   _alerts   = [];
  SystemStatus?       _systemStatus;
  List<BackupRecord>  _backups  = [];
  final List<PlantSnapshot> _manualSnapshots = [];

  /// Tracks the last time each alert ID was shown as a system notification.
  /// Active alerts re-notify every 5 minutes so users who dismiss the banner
  /// will see it again if the condition persists.
  final Map<String, DateTime> _lastNotifiedAt = {};

  late final List<StreamSubscription<dynamic>> _subs;

  // ── Init ─────────────────────────────────────────────────────
  AppState({
    required SensorRepository sensorRepository,
    required DeviceRepository deviceRepository,
    required AlertRepository  alertRepository,
    required SystemRepository systemRepository,
    required CameraRepository cameraRepository,
  }) : _sensorRepo = sensorRepository,
       _deviceRepo = deviceRepository,
       _alertRepo  = alertRepository,
       _systemRepo = systemRepository,
       _cameraRepo = cameraRepository {
    _init();
  }

  void _init() {
    _devices = _deviceRepo.currentDevices;
    _loadBackups();

    _subs = [
      _sensorRepo.sensorStream.listen((r) {
        _readings = r;
        notifyListeners();
      }),
      _deviceRepo.deviceStream.listen((d) {
        _devices = d;
        notifyListeners();
      }),
      _alertRepo.alertStream.listen((a) async {
        final previousIds = _alerts.map((x) => x.id).toSet();
        _alerts = a;
        notifyListeners();

        final now = DateTime.now();
        // Renotify every 2 min so dismissed banners reappear.
        // Tune this in production (e.g. 5–15 min).
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

        // Clean up resolved or disappeared alerts so IDs can re-notify later
        _lastNotifiedAt.removeWhere(
          (id, _) =>
              !a.any((alert) => alert.id == id) ||
              a.any((alert) => alert.id == id && alert.isResolved),
        );
      }),
      _systemRepo.statusStream.listen((s) {
        _systemStatus = s;
        notifyListeners();
      }),
    ];
  }

  Future<void> _loadBackups() async {
    _backups = await _systemRepo.getBackups();
    notifyListeners();
  }

  // ── Getters ──────────────────────────────────────────────────
  List<SensorReading> get readings      => _readings;
  List<DeviceState>   get devices       => _devices;
  bool                get isConnected   => _systemStatus?.isConnected ?? true;
  DateTime            get lastUpdated   => _systemStatus?.lastSeen ?? DateTime.now();
  String              get connectionLabel => isConnected ? 'LIVE' : 'OFFLINE';
  int get alertCount => activeAlerts.length;

  List<AlertRecord>   get allAlerts    => _alerts;
  List<AlertRecord>   get activeAlerts => _alerts.where((a) => !a.isResolved).toList();

  List<AutomationRule> get automationRules => _deviceRepo.automationRules;

  List<DailyImageSet> get growthTimeline  => _cameraRepo.growthTimeline;
  DailyImageSet       get todayImageSet   => _cameraRepo.todayImageSet;
  List<PlantSnapshot> get manualSnapshots => List.unmodifiable(_manualSnapshots);

  List<BackupRecord>  get backups         => _backups;

  // ── Sensors ──────────────────────────────────────────────────
  SensorHistory historyFor(String sensorId) => _sensorRepo.historyFor(sensorId);

  SensorReading? readingById(String id) {
    try { return _readings.firstWhere((r) => r.id == id); }
    catch (_) { return null; }
  }

  // ── Devices ──────────────────────────────────────────────────
  void setDeviceStatus(String deviceId, DeviceStatus status, bool isOn) {
    _deviceRepo.setDeviceStatus(deviceId, status, isOn);
  }

  // ── Camera ───────────────────────────────────────────────────
  PlantSnapshot triggerManualCapture() {
    final snap = _cameraRepo.triggerManualCapture();
    _manualSnapshots.add(snap);
    notifyListeners();
    return snap;
  }

  String nextCaptureLabel() => _cameraRepo.nextCaptureLabel();

  // ── Backup ───────────────────────────────────────────────────
  Future<BackupRecord> createBackup() async {
    final rec = await _systemRepo.createBackup();
    _backups = await _systemRepo.getBackups();
    notifyListeners();
    return rec;
  }

  @override
  void dispose() {
    for (final sub in _subs) sub.cancel();
    _sensorRepo.dispose();
    _deviceRepo.dispose();
    _alertRepo.dispose();
    _systemRepo.dispose();
    _cameraRepo.dispose();
    super.dispose();
  }
}