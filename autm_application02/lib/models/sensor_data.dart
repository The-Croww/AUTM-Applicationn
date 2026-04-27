// ─────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────
enum SensorStatus { normal, warning, alert }
enum DeviceStatus { auto, manualOn, manualOff }
enum CaptureSlot { morning, afternoon, evening }
enum HealthStatus { healthy, fair, poor }

// ─────────────────────────────────────────────────────────────
// SENSOR MODELS
// ─────────────────────────────────────────────────────────────
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

class SensorHistory {
  final String sensorId;
  final List<SensorDataPoint> points;
  SensorHistory({required this.sensorId, required this.points});

  double get average => points.isEmpty
      ? 0
      : points.map((p) => p.value).reduce((a, b) => a + b) / points.length;
  double get min => points.isEmpty
      ? 0
      : points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  double get max => points.isEmpty
      ? 0
      : points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
}

class SensorDataPoint {
  final DateTime time;
  final double value;
  SensorDataPoint({required this.time, required this.value});
}

// ─────────────────────────────────────────────────────────────
// DEVICE MODELS
// ─────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────
// ALERT MODEL
// ─────────────────────────────────────────────────────────────
class AlertRecord {
  final String id;
  final String sensorId;
  final String sensorLabel;
  final double value;
  final String unit;
  final SensorStatus alertType;
  final DateTime createdAt;
  bool isResolved;
  DateTime? resolvedAt;

  AlertRecord({
    required this.id,
    required this.sensorId,
    required this.sensorLabel,
    required this.value,
    required this.unit,
    required this.alertType,
    required this.createdAt,
    this.isResolved = false,
    this.resolvedAt,
  });
}

// ─────────────────────────────────────────────────────────────
// CAMERA / AI MODELS
// ─────────────────────────────────────────────────────────────
class PlantSnapshot {
  final String id;
  final CaptureSlot slot;
  final DateTime capturedAt;
  final bool isManual;
  final int dayNumber;

  PlantSnapshot({
    required this.id,
    required this.slot,
    required this.capturedAt,
    required this.isManual,
    required this.dayNumber,
  });

  String get slotLabel {
    switch (slot) {
      case CaptureSlot.morning:   return 'Morning';
      case CaptureSlot.afternoon: return 'Afternoon';
      case CaptureSlot.evening:   return 'Evening';
    }
  }

  String get slotTime {
    switch (slot) {
      case CaptureSlot.morning:   return '6:00 AM';
      case CaptureSlot.afternoon: return '2:00 PM';
      case CaptureSlot.evening:   return '10:00 PM';
    }
  }
}

class DailyImageSet {
  final DateTime date;
  final int dayNumber;
  final Map<CaptureSlot, PlantSnapshot> snapshots;
  final AIGrowthReport? aiReport;

  DailyImageSet({
    required this.date,
    required this.dayNumber,
    required this.snapshots,
    this.aiReport,
  });

  bool get isComplete => snapshots.length == 3;
  int get captureCount => snapshots.length;

  List<CaptureSlot> get missingSlots => CaptureSlot.values
      .where((s) => !snapshots.containsKey(s))
      .toList();
}

class AIGrowthReport {
  final String id;
  final DateTime date;
  final int dayNumber;
  final int growthScore;
  final HealthStatus healthStatus;
  final String summary;
  final String recommendations;
  final String leafAssessment;
  final String colorAssessment;
  final String stemAssessment;
  final String scoreTrend; // '↑', '↓', '→'
  final int? previousDayScore;
  final DateTime generatedAt;

  AIGrowthReport({
    required this.id,
    required this.date,
    required this.dayNumber,
    required this.growthScore,
    required this.healthStatus,
    required this.summary,
    required this.recommendations,
    required this.leafAssessment,
    required this.colorAssessment,
    required this.stemAssessment,
    required this.scoreTrend,
    this.previousDayScore,
    required this.generatedAt,
  });

  String get healthLabel {
    switch (healthStatus) {
      case HealthStatus.healthy: return 'Healthy';
      case HealthStatus.fair:    return 'Fair';
      case HealthStatus.poor:    return 'Poor';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// BACKUP MODEL
// ─────────────────────────────────────────────────────────────
class BackupRecord {
  final String id;
  final DateTime createdAt;
  final int sensorReadingCount;
  final int alertCount;
  final int snapshotCount;
  final String status; // 'success', 'failed'

  BackupRecord({
    required this.id,
    required this.createdAt,
    required this.sensorReadingCount,
    required this.alertCount,
    required this.snapshotCount,
    required this.status,
  });
}