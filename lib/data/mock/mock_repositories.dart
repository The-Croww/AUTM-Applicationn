// ═══════════════════════════════════════════════════════════════
// MOCK REPOSITORIES
//
// These implement the abstract repository interfaces using
// in-memory data and Stream controllers driven by a single
// shared timer — replacing the old Timer-in-AppState pattern.
//
// To go live: replace MockSensorRepository with
// FirebaseSensorRepository. Nothing else changes.
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';

// ── Shared tick source ────────────────────────────────────────
// One timer drives all mock repositories so they stay in sync.
class _MockClock {
  static final _MockClock _instance = _MockClock._();
  factory _MockClock() => _instance;
  _MockClock._();

  final _controller = StreamController<DateTime>.broadcast();
  Timer? _timer;
  int _subscriberCount = 0;

  Stream<DateTime> get ticks => _controller.stream;

  void addSubscriber() {
    _subscriberCount++;
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.isClosed) _controller.add(DateTime.now());
    });
  }

  void removeSubscriber() {
    _subscriberCount--;
    if (_subscriberCount <= 0) {
      _timer?.cancel();
      _timer = null;
      _subscriberCount = 0;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// MOCK SENSOR REPOSITORY
// ─────────────────────────────────────────────────────────────
class MockSensorRepository implements SensorRepository {
  final _random = Random();
  final _clock  = _MockClock();
  final _historyMap = <String, List<SensorDataPoint>>{};

  // Current simulated values
  double _temp     = 27.5;
  double _humidity = 72.0;
  double _light    = 11500.0;
  double _moisture = 74.0;
  double _ph       = 6.2;
  double _ec       = 1.8;

  late final Stream<List<SensorReading>> _stream;
  StreamSubscription<DateTime>? _sub;

  MockSensorRepository() {
    _clock.addSubscriber();
    _stream = _clock.ticks.map((_) {
      _tick();
      return _buildReadings();
    }).asBroadcastStream();
  }

  @override
  Stream<List<SensorReading>> get sensorStream => _stream;

  @override
  Future<SensorHistory> getHistory(String sensorId) async {
    final hist = _historyMap[sensorId];
    if (hist != null && hist.isNotEmpty) {
      return SensorHistory(sensorId: sensorId, points: List.unmodifiable(hist));
    }
    return _syntheticHistory(sensorId, 48);
  }

  void _tick() {
    _temp     = _clamp(_temp     + _drift(0.3),  24.0, 34.0);
    _humidity = _clamp(_humidity + _drift(0.8),  55.0, 90.0);
    _light    = _clamp(_light    + _drift(300),  8000, 18000);
    _moisture = _clamp(_moisture + _drift(0.4),  55.0, 95.0);
    _ph       = _clamp(_ph       + _drift(0.05), 5.0,  7.5);
    _ec       = _clamp(_ec       + _drift(0.05), 1.0,  3.0);

    final now = DateTime.now();
    for (final r in _buildReadings()) {
      final list = _historyMap.putIfAbsent(r.id, () => []);
      list.add(SensorDataPoint(time: now, value: r.value));
      if (list.length > 288) list.removeAt(0);
    }
  }

  List<SensorReading> _buildReadings() => [
    _r('temperature', 'Air Temperature',    _temp,     '°C',    20, 40, 24, 28, 'thermostat'),
    _r('humidity',    'Relative Humidity',  _humidity, '%',     40, 100, 50, 75, 'water_drop'),
    _r('light',       'Light Intensity',    _light,    'lux',   0, 25000, 10000, 20000, 'wb_sunny'),
    _r('moisture',    'Substrate Moisture', _moisture, '%',     0, 100, 60, 90, 'grass'),
    _r('ph',          'Nutrient pH',        _ph,       'pH',    4.0, 9.0, 5.5, 7.0, 'science'),
    _r('ec',          'Nutrient EC',        _ec,       'mS/cm', 0.5, 4.0, 1.2, 2.5, 'bolt'),
  ];

  SensorReading _r(String id, String label, double value, String unit,
      double min, double max, double wLow, double wHigh, String icon) {
    return SensorReading(
      id: id, label: label,
      value: double.parse(value.toStringAsFixed(2)),
      unit: unit, min: min, max: max,
      warningLow: wLow, warningHigh: wHigh,
      icon: icon, timestamp: DateTime.now(),
    );
  }

  SensorHistory _syntheticHistory(String id, int count) {
    final now = DateTime.now();
    double base, variance;
    switch (id) {
      case 'temperature': base = 27.0;  variance = 2.0;    break;
      case 'humidity':    base = 70.0;  variance = 8.0;    break;
      case 'light':       base = 12000; variance = 2000;   break;
      case 'moisture':    base = 72.0;  variance = 10.0;   break;
      case 'ph':          base = 6.2;   variance = 0.4;    break;
      case 'ec':          base = 1.8;   variance = 0.3;    break;
      default:            base = 50.0;  variance = 5.0;
    }
    double val = base;
    final pts = <SensorDataPoint>[];
    for (int i = count; i >= 0; i--) {
      val = (val + (_random.nextDouble() - 0.5) * variance * 0.4)
          .clamp(base - variance, base + variance);
      pts.add(SensorDataPoint(
        time: now.subtract(Duration(minutes: i * 5)),
        value: double.parse(val.toStringAsFixed(2)),
      ));
    }
    return SensorHistory(sensorId: id, points: pts);
  }

  double _drift(double scale) => (_random.nextDouble() - 0.5) * scale;
  double _clamp(double v, double lo, double hi) => v.clamp(lo, hi);

  @override
  void dispose() {
    _sub?.cancel();
    _clock.removeSubscriber();
  }
}

// ─────────────────────────────────────────────────────────────
// MOCK DEVICE REPOSITORY
// ─────────────────────────────────────────────────────────────
class MockDeviceRepository implements DeviceRepository {
  final _deviceController = StreamController<List<DeviceState>>.broadcast();

  List<DeviceState> _devices = [
    const DeviceState(id: 'exhaust_fan',       label: 'Exhaust Fan',       icon: 'air',        isOn: false, status: DeviceStatus.auto,     triggerReason: 'Auto: temp threshold'),
    const DeviceState(id: 'circulation_fan_1', label: 'Circulation Fan 1', icon: 'cyclone',    isOn: true,  status: DeviceStatus.auto,     triggerReason: 'Auto: humidity threshold'),
    const DeviceState(id: 'circulation_fan_2', label: 'Circulation Fan 2', icon: 'cyclone',    isOn: true,  status: DeviceStatus.auto,     triggerReason: 'Auto: humidity threshold'),
    const DeviceState(id: 'pump',              label: 'Submersible Pump',  icon: 'water',      isOn: false, status: DeviceStatus.auto,     triggerReason: 'Auto: moisture cycle'),
    const DeviceState(id: 'grow_light',        label: 'LED Grow Light',    icon: 'light_mode', isOn: true,  status: DeviceStatus.auto,     triggerReason: 'Auto: light threshold'),
  ];

  @override
  Stream<List<DeviceState>> get deviceStream => _deviceController.stream;

  @override
  Stream<DeviceCommand> sendCommand({
    required String deviceId,
    required DeviceStatus mode,
    required bool targetState,
    required String issuedBy,
  }) async* {
    final cmd = DeviceCommand(
      deviceId:     deviceId,
      mode:         mode,
      targetState:  targetState,
      issuedBy:     issuedBy,
      issuedAt:     DateTime.now(),
      commandStatus: CommandStatus.pending,
    );

    // 1. Emit pending immediately
    yield cmd;

    // 2. Simulate ESP32 processing delay (1.5s)
    await Future.delayed(const Duration(milliseconds: 1500));

    // 3. Apply change to in-memory device list
    _devices = _devices.map((d) {
      if (d.id != deviceId) return d;
      return d.copyWith(
        isOn:          targetState,
        status:        mode,
        lastTriggered: DateTime.now(),
        triggerReason: mode == DeviceStatus.auto
            ? 'Auto: threshold'
            : 'Manual override by $issuedBy',
        updatedBy: issuedBy,
      );
    }).toList();

    // 4. Push updated device list to stream
    _deviceController.add(List.unmodifiable(_devices));

    // 5. Emit acknowledged
    yield cmd.copyWith(
      commandStatus:  CommandStatus.acknowledged,
      acknowledgedAt: DateTime.now(),
    );
  }

  @override
  Future<List<AutomationRule>> getAutomationRules() async => const [
    AutomationRule(sensorId: 'temperature', deviceId: 'exhaust_fan',       triggerLow: 0,     triggerHigh: 28.0,  actionDescription: 'Turn ON exhaust fan when temp > 28°C, OFF when ≤ 26°C'),
    AutomationRule(sensorId: 'humidity',    deviceId: 'circulation_fan_1', triggerLow: 0,     triggerHigh: 75.0,  actionDescription: 'Turn ON circulation fans when RH > 75%, OFF when ≤ 70%'),
    AutomationRule(sensorId: 'moisture',    deviceId: 'pump',              triggerLow: 60.0,  triggerHigh: 100,   actionDescription: 'Run pump for 2 min when moisture < 60%'),
    AutomationRule(sensorId: 'light',       deviceId: 'grow_light',        triggerLow: 10000, triggerHigh: 99999, actionDescription: 'Turn ON grow light when lux < 10,000 (6AM–6PM)'),
  ];

  @override
  void dispose() => _deviceController.close();
}

// ─────────────────────────────────────────────────────────────
// MOCK ALERT REPOSITORY
// ─────────────────────────────────────────────────────────────
class MockAlertRepository implements AlertRepository {
  final _controller    = StreamController<List<AlertRecord>>.broadcast();
  final _clock         = _MockClock();
  final List<AlertRecord> _alerts = [];
  int _idCounter = 0;
  Set<String> _activeAlertSensorIds = {};

  late final StreamSubscription<DateTime> _clockSub;

  MockAlertRepository(Stream<List<SensorReading>> sensorStream) {
    // Listen to sensor stream to auto-generate and resolve alerts
    sensorStream.listen((readings) {
      bool changed = false;
      final now = DateTime.now();

      for (final r in readings) {
        if (r.status == SensorStatus.alert) {
          if (!_activeAlertSensorIds.contains(r.id)) {
            _activeAlertSensorIds.add(r.id);
            _alerts.add(AlertRecord(
              id:          'ALT${++_idCounter}',
              sensorId:    r.id,
              sensorLabel: r.label,
              value:       r.value,
              unit:        r.unit,
              alertType:   SensorStatus.alert,
              createdAt:   now,
            ));
            changed = true;
          }
        } else {
          if (_activeAlertSensorIds.contains(r.id)) {
            _activeAlertSensorIds.remove(r.id);
            // Resolve open alerts for this sensor
            for (int i = 0; i < _alerts.length; i++) {
              if (_alerts[i].sensorId == r.id && !_alerts[i].isResolved) {
                _alerts[i] = _alerts[i].copyWith(
                    isResolved: true, resolvedAt: now);
                changed = true;
              }
            }
          }
        }
      }

      if (changed) _controller.add(List.unmodifiable(_alerts.reversed.toList()));
    });
  }

  @override
  Stream<List<AlertRecord>> get alertStream => _controller.stream;

  @override
  Future<void> resolveAlert(String alertId) async {
    for (int i = 0; i < _alerts.length; i++) {
      if (_alerts[i].id == alertId) {
        _alerts[i] = _alerts[i].copyWith(
            isResolved: true, resolvedAt: DateTime.now());
        break;
      }
    }
    _controller.add(List.unmodifiable(_alerts.reversed.toList()));
  }

  @override
  void dispose() => _controller.close();
}

// ─────────────────────────────────────────────────────────────
// MOCK SYSTEM REPOSITORY
// ─────────────────────────────────────────────────────────────
class MockSystemRepository implements SystemRepository {
  final _controller = StreamController<SystemStatus>.broadcast();
  final _clock      = _MockClock();
  late final StreamSubscription<DateTime> _sub;
  final _backups    = <BackupRecord>[];
  int _backupId     = 0;

  MockSystemRepository() {
    _clock.addSubscriber();
    // Immediately emit connected
    _controller.add(_connected());
    // Re-emit every tick
    _sub = _clock.ticks.listen((_) => _controller.add(_connected()));
  }

  SystemStatus _connected() => SystemStatus(
    isConnected:     true,
    lastSeen:        DateTime.now(),
    firmwareVersion: '1.0.0-mock',
    isDataFresh:     true,
  );

  @override
  Stream<SystemStatus> get systemStream => _controller.stream;

  @override
  Future<BackupRecord> createBackup() async {
    await Future.delayed(const Duration(seconds: 2));
    final rec = BackupRecord(
      id:                 'BKP${++_backupId}',
      createdAt:          DateTime.now(),
      sensorReadingCount: 1440,
      alertCount:         12,
      snapshotCount:      24,
      status:             'success',
    );
    _backups.add(rec);
    return rec;
  }

  @override
  Future<List<BackupRecord>> getBackups() async =>
      List.unmodifiable(_backups.reversed.toList());

  @override
  void dispose() {
    _sub.cancel();
    _clock.removeSubscriber();
    _controller.close();
  }
}