// lib/domain/repositories/repositories.dart
//
// Pure abstract interfaces — no Flutter or Firebase imports.
// Mock and Firebase implementations live in data/ and swap
// in main.dart without touching any other file.

import 'dart:async';
import '../models/sensor_data.dart';

// ── Sensor ───────────────────────────────────────────────────
abstract class SensorRepository {
  /// Emits a new list whenever any sensor value changes.
  Stream<List<SensorReading>> get sensorStream;

  /// Snapshot of the most recent history window for [sensorId].
  SensorHistory historyFor(String sensorId);
}

// ── Device / Actuator ────────────────────────────────────────
abstract class DeviceRepository {
  /// Current list of devices (synchronous snapshot for init).
  List<DeviceState> get currentDevices;

  /// Emits a new list whenever any device state changes.
  Stream<List<DeviceState>> get deviceStream;

  /// All configured automation rules (static / rarely changing).
  List<AutomationRule> get automationRules;

  /// Override a device's control mode.
  void setDeviceStatus(String deviceId, DeviceStatus status, bool isOn);
}

// ── Alerts ───────────────────────────────────────────────────
abstract class AlertRepository {
  /// Emits the full alert list (active + resolved) on any change.
  Stream<List<AlertRecord>> get alertStream;
}

// ── System status ────────────────────────────────────────────
abstract class SystemRepository {
  /// Emits connection-status updates.
  Stream<SystemStatus> get statusStream;
}

// ── Camera / Growth tracking ─────────────────────────────────
abstract class CameraRepository {
  /// Emits today's [DailyImageSet] whenever a new capture arrives.
  Stream<DailyImageSet> get todayStream;

  /// Synchronous snapshot of today's image set (for first frame).
  DailyImageSet get todayImageSet;

  /// Full ordered history of daily image sets, newest first.
  List<DailyImageSet> get growthTimeline;

  /// Out-of-schedule snapshots taken via manual capture.
  List<PlantSnapshot> get manualSnapshots;

  /// Human-readable label for the next scheduled capture.
  String nextCaptureLabel();

  /// Trigger an immediate out-of-schedule capture.
  void triggerManualCapture();
}

// SystemStatus is defined in ../models/models.dart