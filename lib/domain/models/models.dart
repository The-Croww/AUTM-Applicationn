// ═══════════════════════════════════════════════════════════════
// DOMAIN MODELS — Firebase-serializable
// Every model has fromJson() + toJson() so swapping the data
// source (mock → Firebase) requires zero changes to UI code.
// ═══════════════════════════════════════════════════════════════

// ── Enums ──────────────────────────────────────────────────────
enum SensorStatus { normal, warning, alert }
enum DeviceStatus { auto, manualOn, manualOff }
enum CaptureSlot  { morning, afternoon, evening }
enum HealthStatus { healthy, fair, poor }
enum CommandStatus { pending, acknowledged, failed, timedOut }

// ─────────────────────────────────────────────────────────────
// SENSOR MODELS
// ─────────────────────────────────────────────────────────────
class SensorReading {
  final String   id;
  final String   label;
  final double   value;
  final String   unit;
  final double   min;
  final double   max;
  final double   warningLow;
  final double   warningHigh;
  final String   icon;
  final DateTime timestamp;

  const SensorReading({
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

  // ── Firebase deserialization ──────────────────────────────────
  // Firebase RTDB stores: { value: 27.5, timestamp: 1234567890 }
  // The static config (label, min, max etc.) comes from /config/sensors
  factory SensorReading.fromJson(String id, Map<dynamic, dynamic> json, Map<dynamic, dynamic> config) {
    return SensorReading(
      id:          id,
      label:       config['label']      as String? ?? id,
      value:       (json['value']       as num).toDouble(),
      unit:        config['unit']       as String? ?? '',
      min:         (config['min']       as num?)?.toDouble() ?? 0,
      max:         (config['max']       as num?)?.toDouble() ?? 100,
      warningLow:  (config['warningLow']  as num?)?.toDouble() ?? 0,
      warningHigh: (config['warningHigh'] as num?)?.toDouble() ?? 100,
      icon:        config['icon']       as String? ?? 'sensors',
      timestamp:   DateTime.fromMillisecondsSinceEpoch(
                     (json['timestamp'] as num).toInt(), isUtc: true).toLocal(),
    );
  }

  // ── Firebase serialization ────────────────────────────────────
  // ESP32 writes this structure to /sensors/{id}
  Map<String, dynamic> toJson() => {
    'value':     value,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  SensorStatus get status {
    if (value < warningLow || value > warningHigh) return SensorStatus.alert;
    final range  = max - min;
    final buffer = range * 0.1;
    if (value < warningLow + buffer || value > warningHigh - buffer) {
      return SensorStatus.warning;
    }
    return SensorStatus.normal;
  }

  double get percentage => ((value - min) / (max - min)).clamp(0.0, 1.0);

  SensorReading copyWith({double? value, DateTime? timestamp}) => SensorReading(
    id: id, label: label,
    value: value ?? this.value,
    unit: unit, min: min, max: max,
    warningLow: warningLow, warningHigh: warningHigh,
    icon: icon,
    timestamp: timestamp ?? this.timestamp,
  );
}

// ─────────────────────────────────────────────────────────────
class SensorHistory {
  final String              sensorId;
  final List<SensorDataPoint> points;

  const SensorHistory({required this.sensorId, required this.points});

  double get average => points.isEmpty ? 0
      : points.map((p) => p.value).reduce((a, b) => a + b) / points.length;
  double get min => points.isEmpty ? 0
      : points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  double get max => points.isEmpty ? 0
      : points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
}

// ─────────────────────────────────────────────────────────────
class SensorDataPoint {
  final DateTime time;
  final double   value;

  const SensorDataPoint({required this.time, required this.value});

  factory SensorDataPoint.fromJson(Map<dynamic, dynamic> json) => SensorDataPoint(
    time:  DateTime.fromMillisecondsSinceEpoch((json['timestamp'] as num).toInt()),
    value: (json['value'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'timestamp': time.millisecondsSinceEpoch,
    'value':     value,
  };
}

// ─────────────────────────────────────────────────────────────
// DEVICE MODELS
// ─────────────────────────────────────────────────────────────
class DeviceState {
  final String    id;
  final String    label;
  final String    icon;
  final bool      isOn;
  final DeviceStatus status;
  final DateTime? lastTriggered;
  final String?   triggerReason;
  final String?   updatedBy;        // userId — who last changed it

  const DeviceState({
    required this.id,
    required this.label,
    required this.icon,
    required this.isOn,
    required this.status,
    this.lastTriggered,
    this.triggerReason,
    this.updatedBy,
  });

  factory DeviceState.fromJson(String id, Map<dynamic, dynamic> json) {
    return DeviceState(
      id:     id,
      label:  json['label']  as String? ?? id,
      icon:   json['icon']   as String? ?? 'power',
      isOn:   json['isOn']   as bool? ?? false,
      status: _parseStatus(json['mode'] as String?),
      lastTriggered: json['lastTriggered'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['lastTriggered'] as num).toInt())
          : null,
      triggerReason: json['triggerReason'] as String?,
      updatedBy:     json['updatedBy']     as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'label':         label,
    'icon':          icon,
    'isOn':          isOn,
    'mode':          _statusToString(status),
    'lastTriggered': lastTriggered?.millisecondsSinceEpoch,
    'triggerReason': triggerReason,
    'updatedBy':     updatedBy,
  };

  static DeviceStatus _parseStatus(String? s) {
    switch (s) {
      case 'manual_on':  return DeviceStatus.manualOn;
      case 'manual_off': return DeviceStatus.manualOff;
      default:           return DeviceStatus.auto;
    }
  }

  static String _statusToString(DeviceStatus s) {
    switch (s) {
      case DeviceStatus.manualOn:  return 'manual_on';
      case DeviceStatus.manualOff: return 'manual_off';
      default:                     return 'auto';
    }
  }

  DeviceState copyWith({
    bool? isOn, DeviceStatus? status,
    DateTime? lastTriggered, String? triggerReason, String? updatedBy,
  }) => DeviceState(
    id: id, label: label, icon: icon,
    isOn:          isOn          ?? this.isOn,
    status:        status        ?? this.status,
    lastTriggered: lastTriggered ?? this.lastTriggered,
    triggerReason: triggerReason ?? this.triggerReason,
    updatedBy:     updatedBy     ?? this.updatedBy,
  );
}

// ─────────────────────────────────────────────────────────────
// DEVICE COMMAND  — the safe command pattern
// Written by Flutter → /commands/{deviceId}
// Read + executed by ESP32
// ESP32 writes ack back to /commands/{deviceId}/ack
// ─────────────────────────────────────────────────────────────
class DeviceCommand {
  final String        deviceId;
  final DeviceStatus  mode;
  final bool          targetState;
  final String        issuedBy;      // userId
  final DateTime      issuedAt;
  final CommandStatus commandStatus;
  final DateTime?     acknowledgedAt;

  const DeviceCommand({
    required this.deviceId,
    required this.mode,
    required this.targetState,
    required this.issuedBy,
    required this.issuedAt,
    this.commandStatus = CommandStatus.pending,
    this.acknowledgedAt,
  });

  factory DeviceCommand.fromJson(String deviceId, Map<dynamic, dynamic> json) {
    return DeviceCommand(
      deviceId:       deviceId,
      mode:           DeviceState._parseStatus(json['mode'] as String?),
      targetState:    json['targetState']    as bool? ?? false,
      issuedBy:       json['issuedBy']       as String? ?? 'unknown',
      issuedAt:       DateTime.fromMillisecondsSinceEpoch(
                        (json['issuedAt'] as num).toInt()),
      commandStatus:  _parseCommandStatus(json['status'] as String?),
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['acknowledgedAt'] as num).toInt())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode':           DeviceState._statusToString(mode),
    'targetState':    targetState,
    'issuedBy':       issuedBy,
    'issuedAt':       issuedAt.millisecondsSinceEpoch,
    'status':         _commandStatusToString(commandStatus),
    'acknowledgedAt': acknowledgedAt?.millisecondsSinceEpoch,
  };

  static CommandStatus _parseCommandStatus(String? s) {
    switch (s) {
      case 'acknowledged': return CommandStatus.acknowledged;
      case 'failed':       return CommandStatus.failed;
      case 'timed_out':    return CommandStatus.timedOut;
      default:             return CommandStatus.pending;
    }
  }

  static String _commandStatusToString(CommandStatus s) {
    switch (s) {
      case CommandStatus.acknowledged: return 'acknowledged';
      case CommandStatus.failed:       return 'failed';
      case CommandStatus.timedOut:     return 'timed_out';
      default:                         return 'pending';
    }
  }

  bool get isPending       => commandStatus == CommandStatus.pending;
  bool get isAcknowledged  => commandStatus == CommandStatus.acknowledged;

  DeviceCommand copyWith({CommandStatus? commandStatus, DateTime? acknowledgedAt}) =>
      DeviceCommand(
        deviceId: deviceId, mode: mode, targetState: targetState,
        issuedBy: issuedBy, issuedAt: issuedAt,
        commandStatus:  commandStatus  ?? this.commandStatus,
        acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      );
}

// ─────────────────────────────────────────────────────────────
// AUTOMATION RULE
// ─────────────────────────────────────────────────────────────
class AutomationRule {
  final String id;
  final String sensorId;
  final String deviceId;
  final double triggerLow;
  final double triggerHigh;
  final String actionDescription;
  final bool   isActive;

  const AutomationRule({
    required this.id,
    required this.sensorId,
    required this.deviceId,
    required this.triggerLow,
    required this.triggerHigh,
    required this.actionDescription,
    this.isActive = true,
  });

  factory AutomationRule.fromJson(Map<dynamic, dynamic> json) => AutomationRule(
    id:                json['id']                as String ?? '',
    sensorId:          json['sensorId']          as String,
    deviceId:          json['deviceId']          as String,
    triggerLow:        (json['triggerLow']        as num).toDouble(),
    triggerHigh:       (json['triggerHigh']       as num).toDouble(),
    actionDescription: json['actionDescription'] as String? ?? '',
    isActive:          json['isActive']          as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id':                id,
    'sensorId':          sensorId,
    'deviceId':          deviceId,
    'triggerLow':        triggerLow,
    'triggerHigh':       triggerHigh,
    'actionDescription': actionDescription,
    'isActive':          isActive,
  };
}

// ─────────────────────────────────────────────────────────────
// ALERT
// ─────────────────────────────────────────────────────────────
class AlertRecord {
  final String       id;
  final String       sensorId;
  final String       sensorLabel;
  final double       value;
  final String       unit;
  final SensorStatus alertType;
  final DateTime     createdAt;
  bool         isResolved;
  DateTime?    resolvedAt;

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

  factory AlertRecord.fromJson(String id, Map<dynamic, dynamic> json) => AlertRecord(
    id:          id,
    sensorId:    json['sensorId']    as String,
    sensorLabel: json['sensorLabel'] as String? ?? json['sensorId'] as String,
    value:       (json['value']      as num).toDouble(),
    unit:        json['unit']        as String? ?? '',
    alertType:   json['alertType'] == 'warning'
                     ? SensorStatus.warning : SensorStatus.alert,
    createdAt:   DateTime.fromMillisecondsSinceEpoch(
                     (json['createdAt'] as num).toInt()),
    isResolved:  json['isResolved']  as bool? ?? false,
    resolvedAt:  json['resolvedAt'] != null
                     ? DateTime.fromMillisecondsSinceEpoch(
                         (json['resolvedAt'] as num).toInt())
                     : null,
  );

  Map<String, dynamic> toJson() => {
    'id':          id,
    'sensorId':    sensorId,
    'sensorLabel': sensorLabel,
    'value':       value,
    'unit':        unit,
    'alertType':   alertType == SensorStatus.warning ? 'warning' : 'alert',
    'createdAt':   createdAt.millisecondsSinceEpoch,
    'isResolved':  isResolved,
    'resolvedAt':  resolvedAt?.millisecondsSinceEpoch,
  };

  AlertRecord copyWith({bool? isResolved, DateTime? resolvedAt}) => AlertRecord(
    id: id, sensorId: sensorId, sensorLabel: sensorLabel,
    value: value, unit: unit, alertType: alertType, createdAt: createdAt,
    isResolved: isResolved ?? this.isResolved,
    resolvedAt: resolvedAt ?? this.resolvedAt,
  );
}

// ─────────────────────────────────────────────────────────────
// CAMERA + AI MODELS
// ─────────────────────────────────────────────────────────────
class PlantSnapshot {
  final String   id;
  final CaptureSlot slot;
  final DateTime capturedAt;
  final bool     isManual;
  final int      dayNumber;
  final String?  imageUrl;       // Firebase Storage download URL
  final String?  storagePath;    // Firebase Storage path for deletion

  const PlantSnapshot({
    required this.id,
    required this.slot,
    required this.capturedAt,
    required this.isManual,
    required this.dayNumber,
    this.imageUrl,
    this.storagePath,
  });

  factory PlantSnapshot.fromJson(String id, Map<dynamic, dynamic> json) => PlantSnapshot(
    id:          id,
    slot:        _parseSlot(json['slot'] as String?),
    capturedAt:  DateTime.fromMillisecondsSinceEpoch(
                     (json['capturedAt'] as num).toInt()),
    isManual:    json['isManual']    as bool? ?? false,
    dayNumber:   json['dayNumber']   as int? ?? 0,
    imageUrl:    json['imageUrl']    as String?,
    storagePath: json['storagePath'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'slot':        _slotToString(slot),
    'capturedAt':  capturedAt.millisecondsSinceEpoch,
    'isManual':    isManual,
    'dayNumber':   dayNumber,
    'imageUrl':    imageUrl,
    'storagePath': storagePath,
  };

  static CaptureSlot _parseSlot(String? s) {
    switch (s) {
      case 'afternoon': return CaptureSlot.afternoon;
      case 'evening':   return CaptureSlot.evening;
      default:          return CaptureSlot.morning;
    }
  }

  static String _slotToString(CaptureSlot s) {
    switch (s) {
      case CaptureSlot.morning:   return 'morning';
      case CaptureSlot.afternoon: return 'afternoon';
      case CaptureSlot.evening:   return 'evening';
    }
  }

  String get slotLabel  => slot == CaptureSlot.morning   ? 'Morning'
      : slot == CaptureSlot.afternoon ? 'Afternoon' : 'Evening';
  String get slotTime   => slot == CaptureSlot.morning   ? '6:00 AM'
      : slot == CaptureSlot.afternoon ? '2:00 PM'   : '10:00 PM';
}

// ─────────────────────────────────────────────────────────────
class DailyImageSet {
  final DateTime                        date;
  final int                             dayNumber;
  final Map<CaptureSlot, PlantSnapshot> snapshots;
  final AIGrowthReport?                 aiReport;

  const DailyImageSet({
    required this.date,
    required this.dayNumber,
    required this.snapshots,
    this.aiReport,
  });

  bool get isComplete     => snapshots.length == 3;
  int  get captureCount   => snapshots.length;
  List<CaptureSlot> get missingSlots =>
      CaptureSlot.values.where((s) => !snapshots.containsKey(s)).toList();
}

// ─────────────────────────────────────────────────────────────
class AIGrowthReport {
  final String       id;
  final DateTime     date;
  final int          dayNumber;
  final int          growthScore;
  final HealthStatus healthStatus;
  final String       summary;
  final String       recommendations;
  final String       leafAssessment;
  final String       colorAssessment;
  final String       stemAssessment;
  final String       scoreTrend;       // '↑' '↓' '→'
  final int?         previousDayScore;
  final DateTime     generatedAt;

  const AIGrowthReport({
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

  factory AIGrowthReport.fromJson(String id, Map<dynamic, dynamic> json) => AIGrowthReport(
    id:               id,
    date:             DateTime.fromMillisecondsSinceEpoch(
                          (json['date'] as num).toInt()),
    dayNumber:        json['dayNumber']        as int? ?? 0,
    growthScore:      json['growthScore']      as int? ?? 0,
    healthStatus:     _parseHealth(json['healthStatus'] as String?),
    summary:          json['summary']          as String? ?? '',
    recommendations:  json['recommendations']  as String? ?? '',
    leafAssessment:   json['leafAssessment']   as String? ?? '',
    colorAssessment:  json['colorAssessment']  as String? ?? '',
    stemAssessment:   json['stemAssessment']   as String? ?? '',
    scoreTrend:       json['scoreTrend']       as String? ?? '→',
    previousDayScore: json['previousDayScore'] as int?,
    generatedAt:      DateTime.fromMillisecondsSinceEpoch(
                          (json['generatedAt'] as num).toInt()),
  );

  Map<String, dynamic> toJson() => {
    'date':             date.millisecondsSinceEpoch,
    'dayNumber':        dayNumber,
    'growthScore':      growthScore,
    'healthStatus':     _healthToString(healthStatus),
    'summary':          summary,
    'recommendations':  recommendations,
    'leafAssessment':   leafAssessment,
    'colorAssessment':  colorAssessment,
    'stemAssessment':   stemAssessment,
    'scoreTrend':       scoreTrend,
    'previousDayScore': previousDayScore,
    'generatedAt':      generatedAt.millisecondsSinceEpoch,
  };

  static HealthStatus _parseHealth(String? s) {
    switch (s) {
      case 'fair': return HealthStatus.fair;
      case 'poor': return HealthStatus.poor;
      default:     return HealthStatus.healthy;
    }
  }

  static String _healthToString(HealthStatus s) {
    switch (s) {
      case HealthStatus.fair: return 'fair';
      case HealthStatus.poor: return 'poor';
      default:                return 'healthy';
    }
  }

  String get healthLabel => healthStatus == HealthStatus.healthy ? 'Healthy'
      : healthStatus == HealthStatus.fair ? 'Fair' : 'Poor';
}

// ─────────────────────────────────────────────────────────────
// SYSTEM STATUS (replaces BackupRecord + isConnected)
// ─────────────────────────────────────────────────────────────
class SystemStatus {
  final bool     isConnected;
  final DateTime lastSeen;      // last ESP32 heartbeat
  final String   firmwareVersion;
  final bool     isDataFresh;   // lastSeen within threshold

  const SystemStatus({
    required this.isConnected,
    required this.lastSeen,
    required this.firmwareVersion,
    required this.isDataFresh,
  });

  factory SystemStatus.fromJson(Map<dynamic, dynamic> json) => SystemStatus(
    isConnected:     true, // if we receive it, we're connected
    lastSeen:        DateTime.fromMillisecondsSinceEpoch(
                         (json['lastSeen'] as num).toInt()),
    firmwareVersion: json['firmwareVersion'] as String? ?? '0.0.0',
    isDataFresh:     DateTime.now().difference(
                         DateTime.fromMillisecondsSinceEpoch(
                             (json['lastSeen'] as num).toInt()))
                         .inSeconds < 30,
  );

  static SystemStatus offline() => SystemStatus(
    isConnected:     false,
    lastSeen:        DateTime.fromMillisecondsSinceEpoch(0),
    firmwareVersion: '—',
    isDataFresh:     false,
  );
}

// ─────────────────────────────────────────────────────────────
// BACKUP RECORD
// ─────────────────────────────────────────────────────────────
class BackupRecord {
  final String   id;
  final DateTime createdAt;
  final int      sensorReadingCount;
  final int      alertCount;
  final int      snapshotCount;
  final String   status;

  const BackupRecord({
    required this.id,
    required this.createdAt,
    required this.sensorReadingCount,
    required this.alertCount,
    required this.snapshotCount,
    required this.status,
  });

  factory BackupRecord.fromJson(String id, Map<dynamic, dynamic> json) => BackupRecord(
    id:                 id,
    createdAt:          DateTime.fromMillisecondsSinceEpoch(
                            (json['createdAt'] as num).toInt()),
    sensorReadingCount: json['sensorReadingCount'] as int? ?? 0,
    alertCount:         json['alertCount']         as int? ?? 0,
    snapshotCount:      json['snapshotCount']       as int? ?? 0,
    status:             json['status']             as String? ?? 'unknown',
  );

  Map<String, dynamic> toJson() => {
    'createdAt':          createdAt.millisecondsSinceEpoch,
    'sensorReadingCount': sensorReadingCount,
    'alertCount':         alertCount,
    'snapshotCount':      snapshotCount,
    'status':             status,
  };
}