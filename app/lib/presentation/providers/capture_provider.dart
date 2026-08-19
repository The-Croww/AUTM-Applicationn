import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import 'sensor_provider.dart';
import 'growth_provider.dart';

class CaptureProvider extends ChangeNotifier {
  final CameraRepository _cameraRepo;
  GrowthProvider? growthProvider;
  SensorProvider? sensorProvider;

  late DailyImageSet _todayImageSet;
  final List<PlantSnapshot> _manualSnapshots = [];
  final List<DailyImageSet> _allDays = [];
  DailyImageSet? _viewingDaySet;

  CaptureProvider({
    required CameraRepository cameraRepo,
    GrowthProvider? growthProvider,
    SensorProvider? sensorProvider,
  })  : _cameraRepo = cameraRepo,
        this.growthProvider = growthProvider,
        this.sensorProvider = sensorProvider {
    _init();
  }

  DailyImageSet get todayImageSet => _todayImageSet;
  List<PlantSnapshot> get manualSnapshots => List.unmodifiable(_manualSnapshots);
  List<DailyImageSet> get allDays => List.unmodifiable(_allDays);
  bool get isViewingToday => _viewingDaySet == null;
  DailyImageSet get currentDaySet => _viewingDaySet ?? _todayImageSet;

  void _init() {
    _todayImageSet = _cameraRepo.todayImageSet;
    _manualSnapshots.addAll(_cameraRepo.manualSnapshots);
    _allDays.addAll(_cameraRepo.growthTimeline);
    notifyListeners();
  }

  String nextCaptureLabel() => _cameraRepo.nextCaptureLabel();

  PlantSnapshot triggerManualCapture() {
    final snap = _cameraRepo.triggerManualCapture();
    _manualSnapshots.add(snap);
    notifyListeners();
    return snap;
  }

  Future<void> saveSlotCapture({
    required CaptureSlot slot,
    required Uint8List bytes,
    String? localPath,
  }) async {
    final now = DateTime.now();
    final snapshot = PlantSnapshot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      slot: slot,
      capturedAt: now,
      isManual: slot == CaptureSlot.manual,
      dayNumber: _todayImageSet.dayNumber,
      localPath: localPath,
    );

    if (slot == CaptureSlot.manual) {
      _manualSnapshots.add(snapshot);
    } else {
      _todayImageSet.snapshots[slot] = snapshot;
    }

    if (slot != CaptureSlot.manual &&
        _todayImageSet.isComplete &&
        _todayImageSet.aiReport == null) {
      final sensorReadings = <String, double>{};
      for (final reading in sensorProvider?.readings ?? const []) {
        sensorReadings[reading.id] = reading.value;
      }
      await growthProvider?.runAIAnalysis(
        sensorReadings: sensorReadings,
        daySet: _todayImageSet,
      );
    }

    notifyListeners();
  }

  Future<void> replaceSlotCapture({
    required CaptureSlot slot,
    required Uint8List bytes,
    required PlantSnapshot oldSnapshot,
    String? localPath,
  }) async {
    if (oldSnapshot.localPath != null) {
      try {
        final oldFile = File(oldSnapshot.localPath!);
        if (oldFile.existsSync()) {
          oldFile.deleteSync();
          debugPrint('Deleted old local file: ${oldSnapshot.localPath}');
        }
      } catch (e) {
        debugPrint('Failed to delete old local file: $e');
      }
    }

    if (_todayImageSet.aiReport != null) {
      _todayImageSet.aiReport = null;
    }

    final now = DateTime.now();
    final newSnapshot = PlantSnapshot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      slot: slot,
      capturedAt: now,
      isManual: false,
      dayNumber: _todayImageSet.dayNumber,
      localPath: localPath,
    );

    _todayImageSet.snapshots[slot] = newSnapshot;

    if (_todayImageSet.isComplete) {
      final sensorReadings = <String, double>{};
      for (final reading in sensorProvider?.readings ?? const []) {
        sensorReadings[reading.id] = reading.value;
      }
      await growthProvider?.runAIAnalysis(
        sensorReadings: sensorReadings,
        daySet: _todayImageSet,
      );
    }

    notifyListeners();
  }

  Future<void> captureAndSaveSlot(CaptureSlot slot, Uint8List imageBytes) async {
    String? localPath;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final capturesDir = Directory(path.join(appDir.path, 'captures'));
      await capturesDir.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = '${slot.name}_${_todayImageSet.dayNumber}_$timestamp.jpg';
      localPath = path.join(capturesDir.path, fileName);

      await File(localPath).writeAsBytes(imageBytes);
      debugPrint('Local file saved: $localPath');

      await saveSlotCapture(
        slot: slot,
        bytes: imageBytes,
        localPath: localPath,
      );
    } catch (e) {
      if (localPath != null) {
        try { File(localPath).deleteSync(); } catch (_) {}
      }
      rethrow;
    }
  }

  void navigateToDay(int dayNumber) {
    if (dayNumber == _todayImageSet.dayNumber) {
      _viewingDaySet = null;
    } else {
      _viewingDaySet = _allDays.firstWhere(
        (d) => d.dayNumber == dayNumber,
        orElse: () => DailyImageSet(
          date: DateTime.now().subtract(
            Duration(days: _todayImageSet.dayNumber - dayNumber),
          ),
          dayNumber: dayNumber,
        ),
      );
    }
    _manualSnapshots.clear();
    notifyListeners();
  }

  void navigatePrevDay() {
    final target = currentDaySet.dayNumber - 1;
    if (target >= 1) navigateToDay(target);
  }

  void navigateNextDay() {
    final target = currentDaySet.dayNumber + 1;
    if (target <= _todayImageSet.dayNumber) navigateToDay(target);
  }
}
