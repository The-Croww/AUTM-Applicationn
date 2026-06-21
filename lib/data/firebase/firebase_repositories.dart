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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

import 'package:firebase_database/firebase_database.dart';

class FirebaseSensorRepository implements SensorRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  StreamSubscription? _sub;
  StreamController<List<SensorReading>>? _controller;

  // ── Config cache (loaded lazily, refreshed in the background) ──
  Map<String, dynamic> _sensorConfig = {};

  // ── Latest raw sensor snapshot, kept so we can re-emit once the
  //    config (labels/thresholds) arrives without waiting on it. ──
  Map<String, dynamic>? _latestRaw;

  @override
  Stream<List<SensorReading>> get sensorStream {
    // Reuse a single persistent controller so repeated getter access
    // never spins up duplicate listeners.
    final existing = _controller;
    if (existing != null) return existing.stream;

    final controller = StreamController<List<SensorReading>>.broadcast(
      onCancel: () {
        _sub?.cancel();
        _sub = null;
      },
    );
    _controller = controller;

    // Attach the live /sensors listener immediately — do NOT gate it
    // behind the one-time config read. If config is unavailable the
    // readings still render with sensible defaults, and the listener
    // auto-recovers once Firebase auth becomes available.
    _sub = _db.child('/sensors').onValue.listen(
      (event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          _latestRaw = Map<String, dynamic>.from(event.snapshot.value as Map);
          controller.add(_buildReadings(_latestRaw!));
        } else {
          _latestRaw = {};
          controller.add(const []);
        }
      },
      onError: (Object e) {
        // Surface the error without tearing down the stream so a
        // transient (e.g. pre-auth) failure can recover.
        if (!controller.isClosed) controller.addError(e);
      },
    );

    // Load sensor config in parallel. On success, re-emit the latest
    // readings so labels/units/thresholds populate retroactively.
    _loadConfig();

    return controller.stream;
  }

  Future<void> _loadConfig() async {
    try {
      final snap = await _db.child('/config/sensors').get();
      if (snap.exists && snap.value != null) {
        _sensorConfig = Map<String, dynamic>.from(snap.value as Map);
        final raw = _latestRaw;
        final controller = _controller;
        if (raw != null && controller != null && !controller.isClosed) {
          controller.add(_buildReadings(raw));
        }
      }
    } catch (_) {
      // Missing/denied config is non-fatal: readings fall back to
      // defaults. A later sensor event will retry via _latestRaw.
    }
  }

  List<SensorReading> _buildReadings(Map<String, dynamic> data) {
    return data.entries.map((e) {
      return SensorReading.fromJson(
        e.key,
        e.value as Map,
        _sensorConfig[e.key] as Map? ?? {},
      );
    }).toList();
  }

  @override
  SensorHistory historyFor(String sensorId) {
    return SensorHistory(sensorId: sensorId, points: []);
  }

  @override
  Future<SensorHistory> fetchHistory(String sensorId, {Duration duration = const Duration(hours: 6)}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final startTime = now - duration.inMilliseconds;  // ← uses the parameter!
  
    final snap = await _db
        .child('/history/$sensorId')
        .orderByChild('timestamp')
        .startAt(startTime.toDouble())
        .get();
  
    List<SensorDataPoint> points = [];
    if (snap.exists && snap.value != null) {
      points = (snap.value as Map? ?? {}).entries.map((e) {
        return SensorDataPoint.fromJson(Map<String, dynamic>.from(e.value as Map));
      }).toList()
        ..sort((a, b) => a.time.compareTo(b.time));
    }
  
    return SensorHistory(sensorId: sensorId, points: points);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller?.close();
  }
}

// ─────────────────────────────────────────────────────────────
class FirebaseDeviceRepository implements DeviceRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  StreamSubscription? _sub;
  List<DeviceState> _currentDevices = [];
  List<AutomationRule> _automationRules = [];

  @override
  Stream<List<DeviceState>> get deviceStream {
    _db.child('/devices').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _currentDevices = data.entries
            .map((e) => DeviceState.fromJson(
                e.key, Map<String, dynamic>.from(e.value as Map)))
            .toList();
      } else {
        _currentDevices = [];
      }
    });

    // Also load automation rules on init
    _loadAutomationRules();

    return _db.child('/devices').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return data.entries
            .map((e) => DeviceState.fromJson(
                e.key, Map<String, dynamic>.from(e.value as Map)))
            .toList();
      }
      return [];
    });
  }

  Future<void> _loadAutomationRules() async {
    final snap = await _db.child('/config/automationRules').get();
    if (snap.exists && snap.value != null) {
      final data = Map<String, dynamic>.from(snap.value as Map);
      _automationRules = data.entries
          .map((e) => AutomationRule.fromJson(Map<String, dynamic>.from({
            'id': e.key,                    
            ...(e.value as Map),            
          })))
          .toList();
    }
  }

  @override
  List<DeviceState> get currentDevices => _currentDevices;

  @override
  List<AutomationRule> get automationRules => _automationRules;

  @override
  void setDeviceStatus(String deviceId, DeviceStatus status, bool isOn) {
    // Write command to /commands/{deviceId}
    // ESP32 will read this, apply it, and write back to /devices/{deviceId}
    final commandRef = _db.child('/commands/$deviceId');
    
    final commandData = {
      'mode': status.toString().split('.').last,
      'targetState': isOn,
      'issuedBy': 'app',
      'issuedAt': DateTime.now().millisecondsSinceEpoch,
      'status': 'pending',
    };
    
    commandRef.set(commandData);
  }

  @override
  void dispose() {
    _sub?.cancel();
  }
}

// ─────────────────────────────────────────────────────────────
class FirebaseAlertRepository implements AlertRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  @override
  Stream<List<AlertRecord>> get alertStream {
    return _db
        .child('/alerts')
        .onValue
        .map((event) {
          if (event.snapshot.exists && event.snapshot.value != null) {
            final data = Map<String, dynamic>.from(
                event.snapshot.value as Map);
            return data.entries
                .map((e) => AlertRecord.fromJson(
                    e.key, Map<String, dynamic>.from(e.value as Map)))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }
          return [];
        });
  }

  @override
  Future<void> resolveAlert(String alertId) async {
    await _db
        .child('/alerts/$alertId')
        .update({
          'isResolved': true,
          'resolvedAt': DateTime.now().millisecondsSinceEpoch
        });
  }

  @override
  void dispose() {}
}

// ─────────────────────────────────────────────────────────────
class FirebaseSystemRepository implements SystemRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  @override
  Stream<SystemStatus> get statusStream {
    // Watch Firebase's own connection indicator
    final connectedRef = _db.child('/.info/connected');
    // Watch ESP32 heartbeat
    final systemRef = _db.child('/system');

    return connectedRef.onValue.asyncMap((connEvent) async {
      final isConnected = connEvent.snapshot.value as bool? ?? false;
      if (!isConnected) return SystemStatus.offline();

      final sysSnap = await systemRef.get();
      if (!sysSnap.exists) return SystemStatus.offline();
      return SystemStatus.fromJson(
          Map<String, dynamic>.from(sysSnap.value as Map));
    });
  }

  @override
    Future<BackupRecord> createBackup() async { 
    // This would export Firebase data to a Storage JSON file
    // For now, return a mock backup record
      return BackupRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      sensorReadingCount: 0,
      alertCount: 0,
      snapshotCount: 0,
      status: 'completed',
    );
  }

  @override
  Future<List<BackupRecord>> getBackups() async {
    // This would list backups from Firebase Storage
    // For now, return empty list
    return [];
  }

  @override
  void dispose() {}
}

// ─────────────────────────────────────────────────────────────
// Auth Repository — Email/Password + Google Sign-In
// ─────────────────────────────────────────────────────────────
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Returns the currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  /// Stream that emits on every auth state change.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Email + password sign-in.
  @override
  Future<bool> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return true; // throws FirebaseAuthException on failure
  }

  /// Google Sign-In.
  Future<bool> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return false; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
    return true;
  }

  /// Sign out from both Firebase and Google.
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  void dispose() {}
}