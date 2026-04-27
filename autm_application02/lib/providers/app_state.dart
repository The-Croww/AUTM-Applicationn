import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../services/mock_data_service.dart';

class AppState extends ChangeNotifier {
  final _service = MockDataService();
  Timer? _timer;

  List<SensorReading> _readings = [];
  List<DeviceState> _devices = [];
  bool _isConnected = true;
  DateTime _lastUpdated = DateTime.now();
  final List<PlantSnapshot> _manualSnapshots = [];

  // ── Getters ──────────────────────────────────────────────────
  List<SensorReading> get readings      => _readings;
  List<DeviceState>   get devices       => _devices;
  bool                get isConnected   => _isConnected;
  DateTime            get lastUpdated   => _lastUpdated;
  int get alertCount => activeAlerts.length;

  List<AlertRecord>   get allAlerts    => _service.allAlerts;
  List<AlertRecord>   get activeAlerts => _service.activeAlerts;

  List<AutomationRule> get automationRules => _service.automationRules;

  List<DailyImageSet> get growthTimeline  => _service.growthTimeline;
  DailyImageSet       get todayImageSet   => _service.todayImageSet;
  List<PlantSnapshot> get manualSnapshots => List.unmodifiable(_manualSnapshots);

  List<BackupRecord>  get backups         => _service.backups;

  // ── Init ─────────────────────────────────────────────────────
  AppState() {
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _service.tick();
      _refresh();
    });
  }

  void _refresh() {
    _readings    = _service.currentReadings;
    _devices     = _service.deviceStates;
    _lastUpdated = DateTime.now();
    notifyListeners();
  }

  // ── Sensors ──────────────────────────────────────────────────
  SensorHistory historyFor(String sensorId) => _service.historyFor(sensorId);

  SensorReading? readingById(String id) {
    try { return _readings.firstWhere((r) => r.id == id); }
    catch (_) { return null; }
  }

  // ── Devices ──────────────────────────────────────────────────
  void setDeviceStatus(String deviceId, DeviceStatus status, bool isOn) {
    _service.setDeviceStatus(deviceId, status, isOn);
    _refresh();
  }

  // ── Camera ───────────────────────────────────────────────────
  PlantSnapshot triggerManualCapture() {
    final snap = _service.addManualCapture();
    _manualSnapshots.add(snap);
    notifyListeners();
    return snap;
  }

  String nextCaptureLabel() {
    final hour = DateTime.now().hour;
    if (hour < 6)  return 'Morning capture at 6:00 AM';
    if (hour < 14) return 'Afternoon capture at 2:00 PM';
    if (hour < 22) return 'Evening capture at 10:00 PM';
    return 'Morning capture at 6:00 AM tomorrow';
  }

  // ── Backup ───────────────────────────────────────────────────
  Future<BackupRecord> createBackup() async {
    await Future.delayed(const Duration(seconds: 2)); // simulate upload
    final rec = _service.createBackup();
    notifyListeners();
    return rec;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}