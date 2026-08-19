import 'dart:typed_data';
import 'package:automato/domain/models/models.dart';

abstract class MLInferenceService {
  Future<MLPlantFeatures> analyzeImage(Uint8List imageBytes);
}
