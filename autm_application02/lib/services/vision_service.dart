//vision_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../../domain/models/models.dart';

class CloudVisionService {
  // ─────────────────────────────────────────────────────────────
  // PRIMARY: Hugging Face API (Free, More Accurate, Needs Internet)
  // FALLBACK: Local Color Analysis (Offline, Instant, Always Works)
  // ─────────────────────────────────────────────────────────────

  static const String _hfModel = 'smoofles/plant-disease-classifier';
  static const String _hfUrl = 'https://api-inference.huggingface.co/models/$_hfModel';

  Future<VisionResult> analyzePlantImage(Uint8List imageBytes) async {
    // Step 1: ALWAYS do local analysis in background (fast, for fallback + validation)
    final localResult = await _analyzeLocal(imageBytes);

    // Step 2: Try Hugging Face API first (better accuracy)
    try {
      final hfResult = await _analyzeHuggingFace(imageBytes);
      if (hfResult != null) {
        // Merge HF labels with local color validation
        return _mergeWithLocalValidation(hfResult, localResult);
      }
    } catch (e) {
      debugPrint('⚠️ Hugging Face failed, using local analysis: $e');
    }

    // Step 3: Fallback to local analysis only
    debugPrint('🎨 Using local color analysis (offline mode)');
    return _enhanceLocalResult(localResult);
  }

  // ─────────────────────────────────────────────────────────────
  // HUGGING FACE API (Primary - Better Accuracy)
  // Free tier: ~30,000 requests/month
  // ─────────────────────────────────────────────────────────────

  Future<VisionResult?> _analyzeHuggingFace(Uint8List imageBytes) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.post(
        Uri.parse(_hfUrl),
        headers: {'Content-Type': 'application/octet-stream'},
        body: imageBytes,
      ).timeout(const Duration(seconds: 15));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final predictions = (data as List<dynamic>?) ?? [];

        final labels = predictions.map((p) {
          final label = p['label'] as String? ?? 'unknown';
          final score = (p['score'] as num?)?.toDouble() ?? 0;
          return '$label (${(score * 100).round()}%)';
        }).toList();

        debugPrint('🤗 Hugging Face: ${stopwatch.elapsedMilliseconds}ms | Labels: $labels');

        return VisionResult(
          labels: labels,
          objects: [],
          colors: ColorAnalysis(greenScore: 0, yellowScore: 0, brownScore: 0),
          confidence: 0.85,
          isLikelyTomato: true,
          detectedGrowthStage: 'unknown',
        );
      } else if (response.statusCode == 503) {
        // Model is loading (cold start)
        debugPrint('🤗 Hugging Face model loading, retrying in 10s...');
        await Future.delayed(const Duration(seconds: 10));
        return _analyzeHuggingFace(imageBytes); // Retry once
      } else {
        debugPrint('🤗 Hugging Face error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('🤗 Hugging Face failed: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // LOCAL COLOR ANALYSIS (Fallback - Always Works, Offline)
  // ─────────────────────────────────────────────────────────────

  Future<VisionResult> _analyzeLocal(Uint8List imageBytes) async {
    final stopwatch = Stopwatch()..start();

    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final resized = img.copyResize(image, width: 100);

    int totalPixels = 0;
    int greenPixels = 0;
    int yellowPixels = 0;
    int brownPixels = 0;
    int darkPixels = 0;
    int brightPixels = 0;

    double totalR = 0, totalG = 0, totalB = 0;

    for (var y = 0; y < resized.height; y++) {
      for (var x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        totalR += r;
        totalG += g;
        totalB += b;
        totalPixels++;

        if (g > r + 20 && g > b + 10) greenPixels++;
        else if (r > 150 && g > 150 && b < 100) yellowPixels++;
        else if (r > 80 && r < 180 && g < 120 && b < 80) brownPixels++;
        else if (r < 60 && g < 60 && b < 60) darkPixels++;
        else if (r > 180 && g > 180 && b > 140) brightPixels++;
      }
    }

    final avgR = totalR / totalPixels;
    final avgG = totalG / totalPixels;
    final avgB = totalB / totalPixels;

    final greenScore = (greenPixels / totalPixels * 100).clamp(0, 100).toDouble();
    final yellowScore = (yellowPixels / totalPixels * 100).clamp(0, 100).toDouble();
    final brownScore = (brownPixels / totalPixels * 100).clamp(0, 100).toDouble();
    final darkScore = (darkPixels / totalPixels * 100).clamp(0, 100).toDouble();
    final brightScore = (brightPixels / totalPixels * 100).clamp(0, 100).toDouble();

    final healthScore = _calculateHealthScore(greenScore, yellowScore, brownScore, darkScore);
    final vigorScore = _calculateVigorScore(greenScore, brightScore, darkScore);
    final isTomato = _validateTomatoPlant(greenScore, yellowScore, brownScore, brightScore, avgR, avgG, avgB);
    final growthStage = _detectGrowthStageFromColors(greenScore, yellowScore, brownScore, brightScore, darkScore);

    stopwatch.stop();
    debugPrint('🎨 Local analysis: ${stopwatch.elapsedMilliseconds}ms | Green: ${greenScore.round()}% | Yellow: ${yellowScore.round()}% | Brown: ${brownScore.round()}% | Stage: $growthStage | Tomato: $isTomato');

    return VisionResult(
      labels: [],
      objects: [],
      colors: ColorAnalysis(
        greenScore: greenScore,
        yellowScore: yellowScore,
        brownScore: brownScore,
      ),
      confidence: 0.6,
      localScores: LocalScores(
        healthScore: healthScore,
        vigorScore: vigorScore,
        darkSpotScore: darkScore,
        brightnessScore: brightScore,
        avgR: avgR,
        avgG: avgG,
        avgB: avgB,
      ),
      isLikelyTomato: isTomato,
      detectedGrowthStage: growthStage,
    );
  }

  // ── Merge HF Labels with Local Validation ───────────────────
  VisionResult _mergeWithLocalValidation(VisionResult hf, VisionResult local) {
    final labels = <String>[...hf.labels];

    // Add validation warning if not likely tomato
    if (!local.isLikelyTomato) {
      labels.insert(0, '⚠️ NOT CHERRY TOMATO PLANT');
      labels.insert(1, 'validation: ${(local.confidence * 100).round()}% confidence');
    } else {
      labels.insert(0, '✅ likely cherry tomato plant');
    }

    // Add growth stage from local analysis
    labels.add('growth stage: ${local.detectedGrowthStage}');

    // Add color analysis summary
    labels.add('green: ${local.colors.greenScore.round()}%');
    labels.add('yellow: ${local.colors.yellowScore.round()}%');
    labels.add('brown: ${local.colors.brownScore.round()}%');

    return VisionResult(
      labels: labels,
      objects: [],
      colors: local.colors,
      confidence: (hf.confidence + local.confidence) / 2,
      localScores: local.localScores,
      isLikelyTomato: local.isLikelyTomato,
      detectedGrowthStage: local.detectedGrowthStage,
    );
  }

  // ── Enhance Local Result with Heuristic Labels ──────────────
  VisionResult _enhanceLocalResult(VisionResult local) {
    final colors = local.colors;
    final scores = local.localScores;
    final labels = <String>[];

    if (scores == null) return local;

    if (!local.isLikelyTomato) {
      labels.add('⚠️ NOT CHERRY TOMATO PLANT');
      labels.add('low confidence: ${(local.confidence * 100).round()}%');
    } else {
      labels.add('✅ likely cherry tomato plant');
    }

    labels.add('growth stage: ${local.detectedGrowthStage}');

    if (colors.greenScore > 60) {
      labels.add('plant');
      labels.add('leaf');
      if (colors.greenScore > 80) {
        labels.add('healthy plant (${colors.greenScore.round()}% green)');
        labels.add('vibrant foliage');
      } else {
        labels.add('moderate health (${colors.greenScore.round()}% green)');
      }
    }

    if (colors.yellowScore > 15) {
      labels.add('yellowing leaf');
      labels.add('chlorosis (${colors.yellowScore.round()}% yellow)');
      if (colors.yellowScore > 40) labels.add('severe chlorosis');
    }

    if (colors.brownScore > 10) {
      labels.add('brown spots');
      labels.add('necrosis (${colors.brownScore.round()}% brown)');
      if (colors.brownScore > 30) labels.add('advanced decay');
    }

    if (scores.darkSpotScore > 15) {
      labels.add('dark spots');
      labels.add('possible disease (${scores.darkSpotScore.round()}%)');
    }

    if (scores.vigorScore > 75) {
      labels.add('strong growth');
      labels.add('turgid leaves');
    } else if (scores.vigorScore < 40) {
      labels.add('wilting');
      labels.add('stress signs');
    }

    if (labels.isEmpty) {
      labels.add('plant');
      labels.add('unclear health status');
    }

    return VisionResult(
      labels: labels,
      objects: [],
      colors: local.colors,
      confidence: local.confidence,
      localScores: local.localScores,
      isLikelyTomato: local.isLikelyTomato,
      detectedGrowthStage: local.detectedGrowthStage,
    );
  }

  // ── Helper Methods ──────────────────────────────────────────
  double _calculateHealthScore(double green, double yellow, double brown, double dark) {
    var score = green * 0.5;
    score -= yellow * 0.2;
    score -= brown * 0.3;
    score -= dark * 0.4;
    return score.clamp(0, 100);
  }

  double _calculateVigorScore(double green, double bright, double dark) {
    var score = green * 0.4;
    score += bright * 0.3;
    score -= dark * 0.5;
    return score.clamp(0, 100);
  }

  bool _validateTomatoPlant(double green, double yellow, double brown, double brightness, double avgR, double avgG, double avgB) {
    int score = 0;
    if (green > 50) score += 30;
    else if (green > 30) score += 15;
    if (yellow < 40) score += 20;
    else if (yellow < 60) score += 10;
    if (brown < 20) score += 20;
    else if (brown < 40) score += 10;
    if (brightness > 30 && brightness < 80) score += 20;
    else if (brightness > 20) score += 10;
    if (avgG > avgR && avgG > avgB) score += 10;
    return score >= 50;
  }

  String _detectGrowthStageFromColors(double green, double yellow, double brown, double brightness, double dark) {
    if (green > 60 && brightness > 60 && yellow < 15 && brown < 5 && dark < 10) return 'seedling';
    if (yellow > 20 && yellow < 50 && green > 40 && brightness > 40) return 'flowering';
    if ((yellow > 30 || brown > 15) && green > 30 && brightness > 35) return 'fruiting';
    return 'vegetative';
  }
}

// ─────────────────────────────────────────────────────────────
// VISION RESULT MODEL
// ─────────────────────────────────────────────────────────────
class VisionResult {
  final List<String> labels;
  final List<DetectedObject> _detectedObjects;
  final ColorAnalysis colors;
  final double confidence;
  final LocalScores? localScores;
  final bool isLikelyTomato;
  final String detectedGrowthStage;

  List<String> get objects => _detectedObjects.map((o) => o.name).toList();
  List<DetectedObject> get detectedObjects => List.unmodifiable(_detectedObjects);

  VisionResult({
    required this.labels,
    List<DetectedObject>? objects,
    required this.colors,
    required this.confidence,
    this.localScores,
    this.isLikelyTomato = true,
    this.detectedGrowthStage = 'vegetative',
  }) : _detectedObjects = objects ?? [];

  factory VisionResult.fallback() => VisionResult(
    labels: ['plant', 'leaf'],
    objects: [],
    colors: ColorAnalysis(greenScore: 50, yellowScore: 10, brownScore: 5),
    confidence: 0.3,
    isLikelyTomato: false,
    detectedGrowthStage: 'unknown',
  );

  MLPlantFeatures toMLFeatures() {
    final labelText = labels.join(' ').toLowerCase();
    final local = localScores;

    double leafHealth = 70;
    double colorIndex = colors.greenScore;
    double stemVigor = 70;
    double pestSeverity = 0;
    double brown = colors.brownScore;
    final pests = <String>[];
    String growthStage = detectedGrowthStage;

    if (local != null) {
      leafHealth = local.healthScore;
      stemVigor = local.vigorScore;
      if (local.darkSpotScore > 20) {
        pestSeverity = local.darkSpotScore;
        pests.add('possible_disease');
      }
    }

    if (labelText.contains('healthy') || labelText.contains('vibrant')) {
      leafHealth = max(leafHealth, 85);
      stemVigor = max(stemVigor, 80);
    }
    if (labelText.contains('wilt') || labelText.contains('droop') || labelText.contains('stress')) {
      leafHealth = min(leafHealth, 50);
      stemVigor = min(stemVigor, 45);
    }
    if (labelText.contains('spot') || labelText.contains('blight') || labelText.contains('disease')) {
      leafHealth = min(leafHealth, 40);
      pestSeverity = max(pestSeverity, 50);
      pests.add('disease');
    }
    if (labelText.contains('dead') || labelText.contains('dry') || labelText.contains('decay')) {
      leafHealth = min(leafHealth, 20);
      colorIndex = min(colorIndex, 30);
    }
    if (labelText.contains('yellow') || labelText.contains('chlorosis')) {
      colorIndex = min(colorIndex, 45);
    }
    if (labelText.contains('brown') || labelText.contains('necrosis')) {
      brown = max(brown, 60);
      colorIndex = min(colorIndex, 35);
    }

    final pestKeywords = ['aphid', 'mite', 'whitefly', 'caterpillar', 'thrip', 'snail', 'slug', 'insect'];
    for (final pest in pestKeywords) {
      if (labelText.contains(pest)) {
        pestSeverity = max(pestSeverity, 50);
        pests.add(pest);
      }
    }

    return MLPlantFeatures(
      leafHealthScore: leafHealth.clamp(0, 100),
      colorIndex: colorIndex.clamp(0, 100),
      stemVigor: stemVigor.clamp(0, 100),
      brownScore: brown.clamp(0, 100),
      detectedPests: pests.toSet().toList(),
      pestSeverity: pestSeverity.clamp(0, 100),
      growthStage: growthStage,
      labels: labels,
    );
  }
}

class DetectedObject {
  final String name;
  final double confidence;
  DetectedObject({required this.name, required this.confidence});
}

class ColorAnalysis {
  final double greenScore;
  final double yellowScore;
  final double brownScore;

  ColorAnalysis({
    required this.greenScore,
    required this.yellowScore,
    required this.brownScore,
  });

  factory ColorAnalysis.fromVisionResponse(Map<String, dynamic>? response) {
    return ColorAnalysis(greenScore: 50, yellowScore: 10, brownScore: 5);
  }
}

class LocalScores {
  final double healthScore;
  final double vigorScore;
  final double darkSpotScore;
  final double brightnessScore;
  final double avgR;
  final double avgG;
  final double avgB;

  LocalScores({
    required this.healthScore,
    required this.vigorScore,
    required this.darkSpotScore,
    required this.brightnessScore,
    required this.avgR,
    required this.avgG,
    required this.avgB,
  });
}