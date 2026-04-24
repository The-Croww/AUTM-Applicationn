enum SensorStatus { normal, warning, alert }

class SensorReading {
  final String id;
  final String label;
  final double value;
  final String unit;
  final double min;
  final double max;
  final double warningLow;
  final double warningHigh;
  final String icon;
  final DateTime timestamp;

  SensorReading({
    required this.id,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.warningLow,
    required this.warningHigh,
    required this.icon,
    required this.timestamp,
  });

  SensorStatus get status {
    if (value < warningLow || value > warningHigh) return SensorStatus.alert;
    final range = max - min;
    final buffer = range * 0.1;
    if (value < warningLow + buffer || value > warningHigh - buffer) {
      return SensorStatus.warning;
    }
    return SensorStatus.normal;
  }

  double get percentage => ((value - min) / (max - min)).clamp(0.0, 1.0);
}

enum DeviceStatus { auto, manualOn, manualOff }

class DeviceState {
  final String id;
  final String label;
  final String icon;
  final bool isOn;
  final DeviceStatus status;
  final DateTime? lastTriggered;
  final String? triggerReason;

  DeviceState({
    required this.id,
    required this.label,
    required this.icon,
    required this.isOn,
    required this.status,
    this.lastTriggered,
    this.triggerReason,
  });

  DeviceState copyWith({
    bool? isOn,
    DeviceStatus? status,
    DateTime? lastTriggered,
    String? triggerReason,
  }) {
    return DeviceState(
      id: id,
      label: label,
      icon: icon,
      isOn: isOn ?? this.isOn,
      status: status ?? this.status,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      triggerReason: triggerReason ?? this.triggerReason,
    );
  }
}

class SensorHistory {
  final String sensorId;
  final List<SensorDataPoint> points;

  SensorHistory({required this.sensorId, required this.points});
}

class SensorDataPoint {
  final DateTime time;
  final double value;
  SensorDataPoint({required this.time, required this.value});
}

class AutomationRule {
  final String sensorId;
  final String deviceId;
  final double triggerLow;
  final double triggerHigh;
  final String actionDescription;

  AutomationRule({
    required this.sensorId,
    required this.deviceId,
    required this.triggerLow,
    required this.triggerHigh,
    required this.actionDescription,
  });
}