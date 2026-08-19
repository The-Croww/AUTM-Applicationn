import '../../domain/models/models.dart';

class GrowthAnalyzer {
  AIGrowthReport analyzeGrowth({
    required MLPlantFeatures mlFeatures,
    required Map<String, double> sensorReadings,
    required int dayNumber,
    int? previousDayScore,
  }) {
    final sensorList = <SensorReading>[];
    for (final entry in sensorReadings.entries) {
      sensorList.add(SensorReading(
        id: entry.key,
        label: entry.key,
        value: entry.value,
        unit: _unitForSensor(entry.key),
        min: _minForSensor(entry.key),
        max: _maxForSensor(entry.key),
        warningLow: _warningLowForSensor(entry.key),
        warningHigh: _warningHighForSensor(entry.key),
        icon: _iconForSensor(entry.key),
        timestamp: DateTime.now(),
      ));
    }

    final sensorScore = _calculateSensorHealth(sensorList);
    final mlScore = (mlFeatures.leafHealthScore * 0.4 +
                    mlFeatures.colorIndex * 0.3 +
                    mlFeatures.stemVigor * 0.3);
    final growthScore = ((mlScore * 0.6) + (sensorScore * 0.4)).round();

    final risks = _detectRisks(mlFeatures, sensorList);
    final leafAssessment = _describeLeaf(mlFeatures);
    final colorAssessment = _describeColor(mlFeatures);
    final stemAssessment = _describeStem(mlFeatures);
    final recommendations = _generateRecommendations(
      mlFeatures: mlFeatures,
      sensorReadings: sensorList,
      risks: risks,
      dayNumber: dayNumber,
    );
    final healthStatus = _determineHealthStatus(growthScore, risks);
    final summary = _generateSummary(mlFeatures, risks, growthScore);
    final scoreTrend = _calculateTrend(growthScore, previousDayScore);

    return AIGrowthReport(
      id: 'ai_${dayNumber}_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      dayNumber: dayNumber,
      growthScore: growthScore.clamp(0, 100),
      healthStatus: healthStatus,
      summary: summary,
      recommendations: recommendations,
      leafAssessment: leafAssessment,
      colorAssessment: colorAssessment,
      stemAssessment: stemAssessment,
      scoreTrend: scoreTrend,
      previousDayScore: previousDayScore,
      generatedAt: DateTime.now(),
      mlFeatures: mlFeatures,
      detectedRisks: risks,
      sensorSnapshot: List.unmodifiable(sensorList),
    );
  }

  String _unitForSensor(String id) {
    switch (id) {
      case 'temperature': return '°C';
      case 'ph': return 'pH';
      case 'ec': return 'mS/cm';
      case 'humidity': return '%';
      default: return '';
    }
  }

  double _minForSensor(String id) {
    switch (id) {
      case 'temperature': return 0;
      case 'ph': return 0;
      case 'ec': return 0;
      case 'humidity': return 0;
      default: return 0;
    }
  }

  double _maxForSensor(String id) {
    switch (id) {
      case 'temperature': return 50;
      case 'ph': return 14;
      case 'ec': return 5;
      case 'humidity': return 100;
      default: return 100;
    }
  }

  double _warningLowForSensor(String id) {
    switch (id) {
      case 'temperature': return 15;
      case 'ph': return 5.5;
      case 'ec': return 1.0;
      case 'humidity': return 40;
      default: return 0;
    }
  }

  double _warningHighForSensor(String id) {
    switch (id) {
      case 'temperature': return 32;
      case 'ph': return 7.0;
      case 'ec': return 3.0;
      case 'humidity': return 80;
      default: return 100;
    }
  }

  String _iconForSensor(String id) {
    switch (id) {
      case 'temperature': return 'thermostat';
      case 'ph': return 'science';
      case 'ec': return 'water';
      case 'humidity': return 'water_drop';
      default: return 'sensors';
    }
  }

  double _calculateSensorHealth(List<SensorReading> sensors) {
    double totalScore = 0;
    int count = 0;

    for (final sensor in sensors) {
      double score;
      switch (sensor.id) {
        case 'temperature':
          score = sensor.value >= 20 && sensor.value <= 28 ? 100
              : sensor.value >= 15 && sensor.value <= 32 ? 70
              : 40;
          break;
        case 'ph':
          score = sensor.value >= 6.0 && sensor.value <= 6.5 ? 100
              : sensor.value >= 5.5 && sensor.value <= 7.0 ? 75
              : sensor.value >= 5.0 && sensor.value <= 7.5 ? 50
              : 25;
          break;
        case 'ec':
          score = sensor.value >= 1.5 && sensor.value <= 2.5 ? 100
              : sensor.value >= 1.0 && sensor.value <= 3.0 ? 75
              : 50;
          break;
        case 'humidity':
          score = sensor.value >= 60 && sensor.value <= 75 ? 100
              : sensor.value >= 50 && sensor.value <= 80 ? 80
              : sensor.value >= 40 && sensor.value <= 85 ? 60
              : 40;
          break;
        default:
          score = 70;
      }
      totalScore += score;
      count++;
    }

    return count > 0 ? totalScore / count : 70;
  }

  List<String> _detectRisks(MLPlantFeatures ml, List<SensorReading> sensors) {
    final risks = <String>[];

    for (final sensor in sensors) {
      switch (sensor.id) {
        case 'temperature':
          if (sensor.value > 32) risks.add('heat_stress');
          if (sensor.value < 15) risks.add('cold_stress');
          break;
        case 'ph':
          if (sensor.value < 5.5) risks.add('ph_acidic');
          if (sensor.value > 7.0) risks.add('ph_alkaline');
          break;
        case 'ec':
          if (sensor.value > 3.0) risks.add('nutrient_burn');
          if (sensor.value < 1.0) risks.add('nutrient_deficiency');
          break;
        case 'humidity':
          if (sensor.value > 80) risks.add('fungal_risk');
          if (sensor.value < 40) risks.add('transpiration_stress');
          break;
      }
    }

    if (ml.pestSeverity > 30) risks.add('pest_infestation');
    if (ml.leafHealthScore < 50) risks.add('poor_leaf_health');
    if (ml.colorIndex < 40) risks.add('chlorosis');
    if (ml.brownScore > 30) risks.add('necrosis');

    return risks;
  }

  String _describeLeaf(MLPlantFeatures ml) {
    if (ml.leafHealthScore >= 80) {
      return 'Leaves are broad, turgid, and uniformly green with no visible damage or discoloration.';
    } else if (ml.leafHealthScore >= 60) {
      return 'Leaves show minor stress signs — slight curling or edge discoloration detected.';
    } else if (ml.leafHealthScore >= 40) {
      return 'Moderate leaf damage: visible spots, wilting, or pest damage on ${ml.detectedPests.join(', ')}.';
    } else {
      return 'Severe leaf deterioration: extensive necrosis, heavy pest infestation, or advanced disease.';
    }
  }

  String _describeColor(MLPlantFeatures ml) {
    if (ml.colorIndex >= 70) {
      return 'Deep green coloration indicates healthy chlorophyll content and active photosynthesis.';
    } else if (ml.colorIndex >= 50) {
      return 'Light green to yellow-green transition suggests mild chlorosis or nutrient imbalance.';
    } else if (ml.colorIndex >= 30) {
      return 'Yellowing (chlorosis) prominent — likely iron, magnesium, or nitrogen deficiency.';
    } else {
      return 'Severe yellowing/browning indicates advanced nutrient deficiency or disease.';
    }
  }

  String _describeStem(MLPlantFeatures ml) {
    if (ml.stemVigor >= 75) {
      return 'Stem is erect, sturdy, and shows active apical growth with no lesions.';
    } else if (ml.stemVigor >= 50) {
      return 'Stem is somewhat thin or leaning — may indicate etiolation or water stress.';
    } else {
      return 'Weak, spindly stem with possible lesions or damping-off symptoms.';
    }
  }

  String _generateRecommendations({
    required MLPlantFeatures mlFeatures,
    required List<SensorReading> sensorReadings,
    required List<String> risks,
    required int dayNumber,
  }) {
    final actions = <String>[];

    final temp = sensorReadings.firstWhere(
      (s) => s.id == 'temperature',
      orElse: () => SensorReading(
        id: 'temperature', label: 'Temperature', value: 25, unit: '°C',
        min: 0, max: 50, warningLow: 15, warningHigh: 32,
        icon: 'thermostat', timestamp: DateTime.now(),
      ),
    );
    if (temp.value > 32) {
      actions.add('🌡️ Heat Stress: Activate exhaust fans and misting. Consider shade cloth 11AM-3PM. Target: 20-28°C.');
    } else if (temp.value < 15) {
      actions.add('🌡️ Cold Stress: Activate heating. Close ventilation after 6PM. Target: 20-28°C.');
    }

    final ph = sensorReadings.firstWhere(
      (s) => s.id == 'ph',
      orElse: () => SensorReading(
        id: 'ph', label: 'pH', value: 6.2, unit: 'pH',
        min: 0, max: 14, warningLow: 5.5, warningHigh: 7.0,
        icon: 'science', timestamp: DateTime.now(),
      ),
    );
    if (ph.value < 5.5) {
      actions.add('⚗️ pH Too Low: Add pH up (potassium hydroxide) to reservoir. Target: 6.0-6.5 for nutrient uptake.');
    } else if (ph.value > 7.0) {
      actions.add('⚗️ pH Too High: Add pH down (phosphoric acid) to reservoir. Target: 6.0-6.5 for nutrient uptake.');
    }

    final ec = sensorReadings.firstWhere(
      (s) => s.id == 'ec',
      orElse: () => SensorReading(
        id: 'ec', label: 'EC', value: 2.0, unit: 'mS/cm',
        min: 0, max: 5, warningLow: 1.0, warningHigh: 3.0,
        icon: 'water', timestamp: DateTime.now(),
      ),
    );
    if (ec.value < 1.0) {
      actions.add('💧 Nutrient Deficiency: Increase EC to 1.5-2.5 mS/cm. Check reservoir levels and pump function.');
    } else if (ec.value > 3.0) {
      actions.add('💧 Nutrient Burn: Flush system with pH-balanced water. Reduce nutrient concentration by 30%.');
    }

    final humidity = sensorReadings.firstWhere(
      (s) => s.id == 'humidity',
      orElse: () => SensorReading(
        id: 'humidity', label: 'Humidity', value: 65, unit: '%',
        min: 0, max: 100, warningLow: 40, warningHigh: 80,
        icon: 'water_drop', timestamp: DateTime.now(),
      ),
    );
    if (humidity.value > 80) {
      actions.add('💨 High Humidity: Increase ventilation. Monitor for fungal spots. Target: 60-75%.');
    } else if (humidity.value < 40) {
      actions.add('💨 Low Humidity: Activate misting or humidifier. Target: 60-75%.');
    }

    if (mlFeatures.pestSeverity > 30) {
      actions.add('🐛 Pest Alert: ${mlFeatures.detectedPests.join(', ')} detected. Apply neem oil spray to leaf undersides. Increase inspection frequency.');
    }
    if (mlFeatures.colorIndex < 40) {
      actions.add('🍃 Chlorosis: Foliar feed with chelated iron (Fe-EDDHA) and magnesium sulfate. Check root zone pH.');
    }
    if (mlFeatures.leafHealthScore < 50) {
      actions.add('🍂 Leaf Damage: Inspect roots for rot/browning. Ensure drainage holes are clear. Consider hydrogen peroxide flush.');
    }

    if (dayNumber <= 7) {
      actions.add('🌱 Seedling Stage: Maintain high humidity (70-80%), gentle light (PPFD 200-300), avoid overwatering.');
    } else if (dayNumber > 25 && dayNumber <= 45) {
      actions.add('🌸 Flowering Stage: Reduce N, increase P/K. Ensure 12-14 hour dark period for photoperiod varieties.');
    } else if (dayNumber > 45) {
      actions.add('🍅 Fruiting Stage: Maintain steady EC 2.0-2.5. Monitor for blossom end rot (calcium deficiency).');
    }

    return actions.join('\n\n');
  }

  HealthStatus _determineHealthStatus(int score, List<String> risks) {
    if (score >= 80 && risks.isEmpty) return HealthStatus.healthy;
    if (score >= 60 && risks.length <= 1) return HealthStatus.fair;
    return HealthStatus.poor;
  }

  String _generateSummary(MLPlantFeatures ml, List<String> risks, int score) {
    if (score >= 85) {
      return 'Plant exhibits excellent vigor with optimal leaf coloration, robust stem structure, and ideal environmental conditions. Growth trajectory is on track.';
    } else if (score >= 70) {
      return 'Plant health is good with minor deviations. ${risks.isNotEmpty ? 'Address: ${risks.join(', ')}.' : 'Maintain current care regimen.'}';
    } else if (score >= 50) {
      return 'Moderate stress detected. ${risks.take(2).join(' and ')} require immediate attention to prevent yield loss.';
    } else {
      return 'Critical stress levels. Multiple factors (${risks.take(3).join(', ')}) are severely impacting plant health. Intervention required within 24 hours.';
    }
  }

  String _calculateTrend(int current, int? previous) {
    if (previous == null) return '➡️';
    final diff = current - previous;
    if (diff > 5) return '📈';
    if (diff < -5) return '📉';
    return '➡️';
  }
}
