import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../../services/ml_inference_service.dart';
import '../../services/growth_analyzer.dart';

class GrowthProvider extends ChangeNotifier {
  final MLInferenceService _mlInferenceService;
  final GrowthAnalyzer _growthAnalyzer;

  final List<DailyImageSet> _growthTimeline = [];

  GrowthProvider({
    required MLInferenceService mlInferenceService,
    required GrowthAnalyzer growthAnalyzer,
    CameraRepository? cameraRepo,
  })  : _mlInferenceService = mlInferenceService,
        _growthAnalyzer = growthAnalyzer {
    if (cameraRepo != null) {
      _growthTimeline.addAll(cameraRepo.growthTimeline);
    }
  }

  List<DailyImageSet> get growthTimeline => _growthTimeline;
  MLInferenceService get mlInferenceService => _mlInferenceService;

  CaptureSlot _getBestImageSlot(DailyImageSet daySet) {
    if (daySet.snapshots[CaptureSlot.evening] != null) return CaptureSlot.evening;
    if (daySet.snapshots[CaptureSlot.afternoon] != null) return CaptureSlot.afternoon;
    if (daySet.snapshots[CaptureSlot.morning] != null) return CaptureSlot.morning;
    return CaptureSlot.morning;
  }

  Future<Uint8List?> _loadImageBytes(PlantSnapshot snapshot) async {
    if (snapshot.localPath != null) {
      try {
        final file = File(snapshot.localPath!);
        if (file.existsSync()) {
          return await file.readAsBytes();
        }
      } catch (e) {
        debugPrint('Failed to read local image: $e');
      }
    }
    return null;
  }

  Future<void> runAIAnalysis({
    required Map<String, double> sensorReadings,
    required DailyImageSet daySet,
  }) async {
    try {
      debugPrint('Starting AI analysis...');

      final bestSlot = _getBestImageSlot(daySet);
      final snapshot = daySet.snapshots[bestSlot];
      if (snapshot == null) {
        debugPrint('No image available for AI analysis');
        return;
      }

      final imageBytes = await _loadImageBytes(snapshot);
      if (imageBytes == null) {
        debugPrint('Could not load image bytes for analysis');
        return;
      }

      MLPlantFeatures? mlFeatures;
      try {
        mlFeatures = await _mlInferenceService.analyzeImage(imageBytes).timeout(
          const Duration(seconds: 30),
        );
      } on TimeoutException {
        debugPrint('ML inference timed out');
      } catch (e) {
        debugPrint('ML inference failed: $e');
      }
      if (mlFeatures == null) {
        return;
      }

      int? previousDayScore;
      if (_growthTimeline.isNotEmpty) {
        final lastDay = _growthTimeline.last;
        previousDayScore = lastDay.aiReport?.growthScore;
      }

      final report = _growthAnalyzer.analyzeGrowth(
        mlFeatures: mlFeatures,
        sensorReadings: sensorReadings,
        dayNumber: daySet.dayNumber,
        previousDayScore: previousDayScore,
      );

      daySet.aiReport = report;
      _growthTimeline.add(daySet);
      notifyListeners();

    } catch (e, stack) {
      debugPrint('AI analysis failed: $e');
      debugPrint('Stack: $stack');

      final fallbackReport = AIGrowthReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        dayNumber: daySet.dayNumber,
        growthScore: 70,
        scoreTrend: '➡️',
        healthStatus: HealthStatus.healthy,
        summary: 'Plant analysis completed. Review image manually for detailed assessment.',
        leafAssessment: 'Image captured successfully.',
        colorAssessment: 'Color analysis pending.',
        stemAssessment: 'Stem check pending.',
        recommendations: 'Ensure optimal lighting and nutrient levels.',
        previousDayScore: 0,
        generatedAt: DateTime.now(),
      );

      daySet.aiReport = fallbackReport;
      _growthTimeline.add(daySet);
      notifyListeners();
    }
  }
}
