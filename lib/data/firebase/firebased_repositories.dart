// ═══════════════════════════════════════════════════════════════
// FIREBASE REPOSITORIES — Production Implementation
//
// HOW TO ACTIVATE:
//   1. Add to pubspec.yaml:
//        firebase_core: ^3.x.x
//        firebase_database: ^11.x.x
//        firebase_storage: ^12.x.x
//        firebase_messaging: ^15.x.x
//   2. Run: flutterfire configure
//   3. In main.dart, replace:
//        create: (_) => SensorProvider(MockSensorRepository())
//      with:
//        create: (_) => SensorProvider(FirebaseSensorRepository())
//
// NOTHING ELSE CHANGES. UI and providers are fully decoupled.
// ═══════════════════════════════════════════════════════════════

// ignore_for_file: unused_import, dead_code
import 'dart:async';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';

// ── Firebase RTDB structure this implementation expects: ───────
//
//  /sensors/{sensorId}/value          double
//  /sensors/{sensorId}/timestamp      int (ms)
//
//  /devices/{deviceId}/isOn           bool
//  /devices/{deviceId}/mode           string
//  /devices/{deviceId}/lastTriggered  int (ms)
//  /devices/{deviceId}/triggerReason  string
//  /devices/{deviceId}/updatedBy      string
//
//  /commands/{deviceId}/mode          string
//  /commands/{deviceId}/targetState   bool
//  /commands/{deviceId}/issuedBy      string
//  /commands/{deviceId}/issuedAt      int (ms)
//  /commands/{deviceId}/status        string  ← ESP32 writes this
//  /commands/{deviceId}/acknowledgedAt int (ms) ← ESP32 writes this
//
//  /alerts/{alertId}/...
//
//  /captures/{YYYY-MM-DD}/{slot}/imageUrl    string
//  /captures/{YYYY-MM-DD}/{slot}/storagePath string
//  /captures/{YYYY-MM-DD}/{slot}/capturedAt  int (ms)
//
//  /ai_reports/{YYYY-MM-DD}/...
//
//  /system/lastSeen         int (ms)   ← ESP32 writes every 30s
//  /system/firmwareVersion  string
//
//  /config/sensors/{id}/label, unit, min, max, warningLow, warningHigh, icon
//  /config/automationRules/{id}/...
// ───────────────────────────────────────────────────────────────

// Uncomment when Firebase packages are added:
// import 'package:firebase_database/firebase_database.dart';

class FirebaseSensorRepository implements SensorRepository {
  // final _db = FirebaseDatabase.instance;
  // StreamSubscription? _sub;
  // StreamController<List<SensorReading>>? _controller;

  // ── Config cache (loaded once on init) ────────────────────────
  // Map<String, dynamic> _sensorConfig = {};

  @override
  Stream<List<SensorReading>> get sensorStream {
    // PRODUCTION IMPLEMENTATION:
    //
    // final controller = StreamController<List<SensorReading>>.broadcast();
    //
    // // Load config once
    // _db.ref('/config/sensors').get().then((snap) {
    //   _sensorConfig = Map<String, dynamic>.from(snap.value as Map);
    //
    //   // Then listen to live readings
    //   _db.ref('/sensors').onValue.listen((event) {
    //     final data = Map<String, dynamic>.from(event.snapshot.value as Map);
    //     final readings = data.entries.map((e) {
    //       return SensorReading.fromJson(
    //         e.key,
    //         e.value as Map,
    //         _sensorConfig[e.key] as Map? ?? {},
    //       );
    //     }).toList();
    //     controller.add(readings);
    //   });
    // });
    //
    // return controller.stream;

    throw UnimplementedError('Add firebase_database package first.');
  }

  @override
  Future<SensorHistory> getHistory(String sensorId) async {
    // PRODUCTION IMPLEMENTATION:
    //
    // final now = DateTime.now().millisecondsSinceEpoch;
    // final sixHoursAgo = now - (6 * 60 * 60 * 1000);
    //
    // final snap = await _db
    //     .ref('/history/$sensorId')
    //     .orderByChild('timestamp')
    //     .startAt(sixHoursAgo)
    //     .get();
    //
    // final points = (snap.value as Map? ?? {}).entries.map((e) {
    //   return SensorDataPoint.fromJson(Map<String, dynamic>.from(e.value as Map));
    // }).toList()
    //   ..sort((a, b) => a.time.compareTo(b.time));
    //
    // return SensorHistory(sensorId: sensorId, points: points);

    throw UnimplementedError('Add firebase_database package first.');
  }

  @override
  void dispose() {
    // _sub?.cancel();
    // _controller?.close();
  }
}

// ─────────────────────────────────────────────────────────────
class FirebaseDeviceRepository implements DeviceRepository {

  @override
  Stream<List<DeviceState>> get deviceStream {
    // PRODUCTION IMPLEMENTATION:
    //
    // return FirebaseDatabase.instance
    //     .ref('/devices')
    //     .onValue
    //     .map((event) {
    //       final data = Map<String, dynamic>.from(
    //           event.snapshot.value as Map? ?? {});
    //       return data.entries
    //           .map((e) => DeviceState.fromJson(
    //               e.key, Map<String, dynamic>.from(e.value as Map)))
    //           .toList();
    //     });

    throw UnimplementedError('Add firebase_database package first.');
  }

  @override
  Stream<DeviceCommand> sendCommand({
    required String deviceId,
    required DeviceStatus mode,
    required bool targetState,
    required String issuedBy,
  }) async* {
    // PRODUCTION IMPLEMENTATION:
    //
    // final db = FirebaseDatabase.instance;
    // final cmdRef = db.ref('/commands/$deviceId');
    //
    // final cmd = DeviceCommand(
    //   deviceId:     deviceId,
    //   mode:         mode,
    //   targetState:  targetState,
    //   issuedBy:     issuedBy,
    //   issuedAt:     DateTime.now(),
    //   commandStatus: CommandStatus.pending,
    // );
    //
    // // 1. Write command to Firebase
    // await cmdRef.set(cmd.toJson());
    // yield cmd;  // emit pending
    //
    // // 2. Wait for ESP32 acknowledgment (with 10s timeout)
    // final completer = Completer<DeviceCommand>();
    // late StreamSubscription sub;
    //
    // sub = cmdRef.onValue.listen((event) {
    //   final data = Map<String, dynamic>.from(event.snapshot.value as Map);
    //   final updated = DeviceCommand.fromJson(deviceId, data);
    //   if (!updated.isPending && !completer.isCompleted) {
    //     completer.complete(updated);
    //     sub.cancel();
    //   }
    // });
    //
    // final acked = await completer.future.timeout(
    //   const Duration(seconds: 10),
    //   onTimeout: () {
    //     sub.cancel();
    //     return cmd.copyWith(commandStatus: CommandStatus.timedOut);
    //   },
    // );
    //
    // yield acked;

    throw UnimplementedError('Add firebase_database package first.');
  }

  @override
  Future<List<AutomationRule>> getAutomationRules() async {
    // PRODUCTION IMPLEMENTATION:
    //
    // final snap = await FirebaseDatabase.instance
    //     .ref('/config/automationRules')
    //     .get();
    // final data = Map<String, dynamic>.from(snap.value as Map? ?? {});
    // return data.values
    //     .map((e) => AutomationRule.fromJson(Map<String, dynamic>.from(e as Map)))
    //     .toList();

    throw UnimplementedError('Add firebase_database package first.');
  }

  @override
  void dispose() {}
}

// ─────────────────────────────────────────────────────────────
class FirebaseAlertRepository implements AlertRepository {

  @override
  Stream<List<AlertRecord>> get alertStream {
    // PRODUCTION IMPLEMENTATION:
    //
    // return FirebaseDatabase.instance
    //     .ref('/alerts')
    //     .orderByChild('createdAt')
    //     .limitToLast(50)
    //     .onValue
    //     .map((event) {
    //       final data = Map<String, dynamic>.from(
    //           event.snapshot.value as Map? ?? {});
    //       return data.entries
    //           .map((e) => AlertRecord.fromJson(
    //               e.key, Map<String, dynamic>.from(e.value as Map)))
    //           .toList()
    //         ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    //     });

    throw UnimplementedError('Add firebase_database package first.');
  }

  @override
  Future<void> resolveAlert(String alertId) async {
    // await FirebaseDatabase.instance
    //     .ref('/alerts/$alertId')
    //     .update({'isResolved': true, 'resolvedAt': DateTime.now().millisecondsSinceEpoch});
    throw UnimplementedError('Add firebase_database package first.');
  }

  @override
  void dispose() {}
}

// ─────────────────────────────────────────────────────────────
class FirebaseSystemRepository implements SystemRepository {

  @override
  Stream<SystemStatus> get systemStream {
    // PRODUCTION IMPLEMENTATION:
    //
    // // Watch Firebase's own connection indicator
    // final connectedRef = FirebaseDatabase.instance.ref('/.info/connected');
    // // Watch ESP32 heartbeat
    // final systemRef = FirebaseDatabase.instance.ref('/system');
    //
    // return connectedRef.onValue.asyncMap((connEvent) async {
    //   final isConnected = connEvent.snapshot.value as bool? ?? false;
    //   if (!isConnected) return SystemStatus.offline();
    //
    //   final sysSnap = await systemRef.get();
    //   if (!sysSnap.exists) return SystemStatus.offline();
    //   return SystemStatus.fromJson(
    //       Map<String, dynamic>.from(sysSnap.value as Map));
    // });

    throw UnimplementedError('Add firebase_database package first.');
  }

  @override
  Future<BackupRecord> createBackup() async {
    // This would export Firebase data to a Storage JSON file
    throw UnimplementedError('Add firebase_database package first.');
  }

  @override
  Future<List<BackupRecord>> getBackups() async {
    throw UnimplementedError('Add firebase_database package first.');
  }

  @override
  void dispose() {}
}