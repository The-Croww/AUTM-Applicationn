import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/sensor_data.dart';
import '../../domain/repositories/repositories.dart';

class SensorProvider extends ChangeNotifier {
  final SensorRepository _sensorRepo;
  StreamSubscription<List<SensorReading>>? _sub;

  List<SensorReading> _readings = [];

  SensorProvider({required SensorRepository sensorRepo}) : _sensorRepo = sensorRepo {
    _sub = _sensorRepo.sensorStream.listen((r) {
      _readings = r;
      notifyListeners();
    });
  }

  List<SensorReading> get readings => _readings;

  SensorHistory historyFor(String sensorId) => _sensorRepo.historyFor(sensorId);

  Future<SensorHistory> fetchHistory(
    String sensorId, {
    Duration duration = const Duration(hours: 6),
  }) => _sensorRepo.fetchHistory(sensorId, duration: duration);

  SensorReading? readingById(String id) {
    try {
      return _readings.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sensorRepo.dispose();
    super.dispose();
  }
}
