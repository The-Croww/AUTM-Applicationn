import 'dart:typed_data';
import 'package:automato/domain/models/models.dart';
import 'ml_inference_service.dart';

class PlaceholderMLInferenceService implements MLInferenceService {
  @override
  Future<MLPlantFeatures> analyzeImage(Uint8List imageBytes) async {
    return const MLPlantFeatures(
      leafHealthScore: 70,
      colorIndex: 70,
      stemVigor: 70,
      pestSeverity: 0,
      brownScore: 0,
      detectedPests: [],
      labels: [],
      growthStage: 'vegetative',
    );
  }
}
