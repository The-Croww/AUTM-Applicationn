import 'dart:async';
import 'dart:math';
import '../models/sensor_data.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  final _random = Random();
  final _sensorHistory = <String, List<SensorDataPoint>>{};

  // Current simulated values (drift over time)
  double _temp = 27.5;
  double _humidity = 72.0;
  double _light = 11500.0;
  double _moisture = 74.0;
  double _ph = 6.2;
  double _ec = 1.8;

  List<SensorReading> get currentReadings => [
        SensorReading(
          id: 'temperature',
          label: 'Air Temperature',
          value: _temp,
          unit: '°C',
          min: 20,
          max: 40,
          warningLow: 24,
          warningHigh: 28,
          icon: 'thermostat',
          timestamp: DateTime.now(),
        ),
        SensorReading(
          id: 'humidity',
          label: 'Relative Humidity',
          value: _humidity,
          unit: '%',
          min: 40,
          max: 100,
          warningLow: 50,
          warningHigh: 75,
          icon: 'water_drop',
          timestamp: DateTime.now(),
        ),
        SensorReading(
          id: 'light',
          label: 'Light Intensity',
          value: _light,
          unit: 'lux',
          min: 0,
          max: 25000,
          warningLow: 10000,
          warningHigh: 20000,
          icon: 'wb_sunny',
          timestamp: DateTime.now(),
        ),
        SensorReading(
          id: 'moisture',
          label: 'Substrate Moisture',
          value: _moisture,
          unit: '%',
          min: 0,
          max: 100,
          warningLow: 60,
          warningHigh: 90,
          icon: 'grass',
          timestamp: DateTime.now(),
        ),
        SensorReading(
          id: 'ph',
          label: 'Nutrient pH',
          value: _ph,
          unit: 'pH',
          min: 4.0,
          max: 9.0,
          warningLow: 5.5,
          warningHigh: 7.0,
          icon: 'science',
          timestamp: DateTime.now(),
        ),
        SensorReading(
          id: 'ec',
          label: 'Nutrient EC',
          value: _ec,
          unit: 'mS/cm',
          min: 0.5,
          max: 4.0,
          warningLow: 1.2,
          warningHigh: 2.5,
          icon: 'bolt',
          timestamp: DateTime.now(),
        ),
      ];

  List<DeviceState> _deviceStates = [
    DeviceState(
      id: 'exhaust_fan',
      label: 'Exhaust Fan',
      icon: 'air',
      isOn: false,
      status: DeviceStatus.auto,
      triggerReason: 'Auto: temp threshold',
    ),
    DeviceState(
      id: 'circulation_fan_1',
      label: 'Circulation Fan 1',
      icon: 'cyclone',
      isOn: true,
      status: DeviceStatus.auto,
      triggerReason: 'Auto: humidity threshold',
    ),
    DeviceState(
      id: 'circulation_fan_2',
      label: 'Circulation Fan 2',
      icon: 'cyclone',
      isOn: true,
      status: DeviceStatus.auto,
      triggerReason: 'Auto: humidity threshold',
    ),
    DeviceState(
      id: 'pump',
      label: 'Submersible Pump',
      icon: 'water',
      isOn: false,
      status: DeviceStatus.auto,
      lastTriggered: DateTime.now().subtract(const Duration(minutes: 23)),
      triggerReason: 'Auto: moisture cycle',
    ),
    DeviceState(
      id: 'grow_light',
      label: 'LED Grow Light',
      icon: 'light_mode',
      isOn: true,
      status: DeviceStatus.auto,
      triggerReason: 'Auto: light threshold',
    ),
  ];

  List<DeviceState> get deviceStates => List.unmodifiable(_deviceStates);

  // Tick: advance simulation by one step
  void tick() {
    _temp = _clamp(_temp + _drift(0.3), 24.0, 34.0);
    _humidity = _clamp(_humidity + _drift(0.8), 55.0, 90.0);
    _light = _clamp(_light + _drift(300), 8000, 18000);
    _moisture = _clamp(_moisture + _drift(0.4), 55.0, 95.0);
    _ph = _clamp(_ph + _drift(0.05), 5.0, 7.5);
    _ec = _clamp(_ec + _drift(0.05), 1.0, 3.0);

    // Record history
    final now = DateTime.now();
    for (final r in currentReadings) {
      _sensorHistory.putIfAbsent(r.id, () => []).add(
            SensorDataPoint(time: now, value: r.value),
          );
      // Keep last 288 points (~24h at 5min intervals)
      final hist = _sensorHistory[r.id]!;
      if (hist.length > 288) hist.removeAt(0);
    }
  }

  SensorHistory historyFor(String sensorId, {int points = 48}) {
    final hist = _sensorHistory[sensorId] ?? [];
    if (hist.isEmpty) {
      // Generate synthetic history on first call
      return _generateSyntheticHistory(sensorId, points);
    }
    final slice = hist.length > points ? hist.sublist(hist.length - points) : hist;
    return SensorHistory(sensorId: sensorId, points: slice);
  }

  SensorHistory _generateSyntheticHistory(String sensorId, int count) {
    final now = DateTime.now();
    final points = <SensorDataPoint>[];
    double base;
    double variance;

    switch (sensorId) {
      case 'temperature': base = 27.0; variance = 2.0; break;
      case 'humidity':    base = 70.0; variance = 8.0; break;
      case 'light':       base = 12000; variance = 2000; break;
      case 'moisture':    base = 72.0; variance = 10.0; break;
      case 'ph':          base = 6.2;  variance = 0.4; break;
      case 'ec':          base = 1.8;  variance = 0.3; break;
      default:            base = 50.0; variance = 5.0;
    }

    double val = base;
    for (int i = count; i >= 0; i--) {
      val = val + (_random.nextDouble() - 0.5) * variance * 0.4;
      val = val.clamp(base - variance, base + variance);
      points.add(SensorDataPoint(
        time: now.subtract(Duration(minutes: i * 5)),
        value: double.parse(val.toStringAsFixed(2)),
      ));
    }
    return SensorHistory(sensorId: sensorId, points: points);
  }

  void setDeviceStatus(String deviceId, DeviceStatus status, bool isOn) {
    _deviceStates = _deviceStates.map((d) {
      if (d.id == deviceId) {
        return d.copyWith(
          status: status,
          isOn: isOn,
          lastTriggered: DateTime.now(),
          triggerReason: status == DeviceStatus.auto ? 'Auto: threshold' : 'Manual override',
        );
      }
      return d;
    }).toList();
  }

  List<AutomationRule> get automationRules => [
        AutomationRule(
          sensorId: 'temperature',
          deviceId: 'exhaust_fan',
          triggerLow: 0,
          triggerHigh: 28.0,
          actionDescription: 'Turn ON exhaust fan when temp > 28°C, OFF when ≤ 26°C',
        ),
        AutomationRule(
          sensorId: 'humidity',
          deviceId: 'circulation_fan_1',
          triggerLow: 0,
          triggerHigh: 75.0,
          actionDescription: 'Turn ON circulation fans when RH > 75%, OFF when ≤ 70%',
        ),
        AutomationRule(
          sensorId: 'moisture',
          deviceId: 'pump',
          triggerLow: 60.0,
          triggerHigh: 100,
          actionDescription: 'Run pump for 2 min when moisture < 60%',
        ),
        AutomationRule(
          sensorId: 'light',
          deviceId: 'grow_light',
          triggerLow: 10000,
          triggerHigh: 99999,
          actionDescription: 'Turn ON grow light when lux < 10,000 (6AM–6PM)',
        ),
      ];

  double _drift(double scale) => (_random.nextDouble() - 0.5) * scale;
  double _clamp(double v, double lo, double hi) => v.clamp(lo, hi);
}