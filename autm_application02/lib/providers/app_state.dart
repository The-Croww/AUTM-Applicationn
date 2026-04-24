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

  List<SensorReading> get readings => _readings;
  List<DeviceState> get devices => _devices;
  bool get isConnected => _isConnected;
  DateTime get lastUpdated => _lastUpdated;

  // Quick alert count for notification badge
  int get alertCount => _readings.where((r) => r.status == SensorStatus.alert).length;

  AppState() {
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _service.tick();
      _refresh();
    });
  }

  void _refresh() {
    _readings = _service.currentReadings;
    _devices = _service.deviceStates;
    _lastUpdated = DateTime.now();
    notifyListeners();
  }

  SensorHistory historyFor(String sensorId) => _service.historyFor(sensorId);

  List<AutomationRule> get automationRules => _service.automationRules;

  void setDeviceStatus(String deviceId, DeviceStatus status, bool isOn) {
    _service.setDeviceStatus(deviceId, status, isOn);
    _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}