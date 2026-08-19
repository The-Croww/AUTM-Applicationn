import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/sensor_data.dart';
import '../../domain/repositories/repositories.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceRepository _deviceRepo;
  StreamSubscription<List<DeviceState>>? _sub;

  List<DeviceState> _devices = [];

  DeviceProvider({required DeviceRepository deviceRepo})
      : _deviceRepo = deviceRepo {
    _devices = _deviceRepo.currentDevices;
    _sub = _deviceRepo.deviceStream.listen((d) {
      _devices = d;
      notifyListeners();
    });
  }

  List<DeviceState> get devices => _devices;
  List<AutomationRule> get automationRules => _deviceRepo.automationRules;

  void setDeviceStatus(String deviceId, DeviceStatus status, bool isOn) {
    _deviceRepo.setDeviceStatus(deviceId, status, isOn);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _deviceRepo.dispose();
    super.dispose();
  }
}
