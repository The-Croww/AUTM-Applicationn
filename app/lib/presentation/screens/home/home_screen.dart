//home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:automato/domain/models/sensor_data.dart';
import 'package:automato/presentation/providers/app_state.dart';
import 'package:automato/presentation/theme/app_theme.dart';
import 'package:automato/presentation/widgets/scenario_video_player.dart';

// ─────────────────────────────────────────────────────────────
// HOME SCREEN — Live/Demo Toggle with Scene Card, Actions, Trends
// ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDemoMode = false;

  // Demo scenario index
  int _demoScenarioIndex = 0;

  final List<DemoScenarioData> _demoScenarios = [
    // 1. PANIC / CRITICAL
    DemoScenarioData(
      title: 'Panic / Critical',
      tag: 'PANIC',
      subtitle: 'Emergency State',
      videoAsset: 'assets/videos/panic_critical.mp4',
      quote: '"MAYDAY MAYDAY MAYDAY — I am on the brink of death!"',
      quoteColor: const Color(0xFFC0392B),
      cardColor: const Color(0xFFFDE8E8),
      borderColor: const Color(0xFFE74C3C),
      actions: [
        DemoAction(icon: Icons.air, label: 'Turn on Exhaust Fan to vent hot air', hasToggle: true, isCritical: true),
        DemoAction(icon: Icons.wind_power, label: 'Boost Ventilation Fans to cool canopy', hasToggle: true, isCritical: true),
        DemoAction(icon: Icons.water_drop, label: 'Run Water Pump to irrigate immediately', hasToggle: true, isCritical: true),
        DemoAction(icon: Icons.door_front_door_outlined, label: 'Open side roll up vent for airflow', hasToggle: false, isCritical: true),
      ],
      sensorTrends: [
        DemoTrend('TEMP', 38.0, '°C', 0.95, true),
        DemoTrend('HUMID', 70.0, '%', 0.6, false),
        DemoTrend('LIGHT', 6000.0, 'lux', 0.5, false),
        DemoTrend('SOIL', 22.0, '%', 0.25, true),
        DemoTrend('pH', 6.50, '', 0.5, false),
        DemoTrend('EC', 2.00, 'mS/cm', 0.5, false),
      ],
    ),

    // 2. HIGH TEMPERATURE
    DemoScenarioData(
      title: 'High Temperature',
      tag: 'WARNING',
      subtitle: 'Heat Stress',
      videoAsset: 'assets/videos/high_temperature.mp4',
      quote: '"It feels like an oven in here!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        DemoAction(icon: Icons.air, label: 'Turn on Exhaust Fan to vent hot air', hasToggle: true),
        DemoAction(icon: Icons.wind_power, label: 'Boost Ventilation Fans', hasToggle: true),
        DemoAction(icon: Icons.door_front_door_outlined, label: 'Open side roll up vent', hasToggle: false),
      ],
      sensorTrends: [
        DemoTrend('TEMP', 35.0, '°C', 0.88, true),
        DemoTrend('HUMID', 55.0, '%', 0.45, false),
        DemoTrend('SOIL', 45.0, '%', 0.45, false),
      ],
    ),

    // 3. LOW TEMPERATURE
    DemoScenarioData(
      title: 'Low Temperature',
      tag: 'WARNING',
      subtitle: 'Cold Stress',
      videoAsset: 'assets/videos/low_temperature.mp4',
      quote: '"I am freezing — my growth has stopped!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        DemoAction(icon: Icons.wind_power, label: 'Reduce Ventilation Fan speed', hasToggle: true),
        DemoAction(icon: Icons.door_front_door_outlined, label: 'Close side roll up vent', hasToggle: false),
      ],
      sensorTrends: [
        DemoTrend('TEMP', 15.0, '°C', 0.3, true),
        DemoTrend('HUMID', 45.0, '%', 0.38, false),
        DemoTrend('SOIL', 50.0, '%', 0.5, false),
      ],
    ),

    // 4. HIGH HUMIDITY
    DemoScenarioData(
      title: 'High Humidity',
      tag: 'WARNING',
      subtitle: 'Mold Risk',
      videoAsset: 'assets/videos/high_humidity.mp4',
      quote: '"It is so humid, mold is growing on me!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        DemoAction(icon: Icons.air, label: 'Turn on Exhaust Fan to reduce humidity', hasToggle: true),
        DemoAction(icon: Icons.wind_power, label: 'Boost Ventilation Fans', hasToggle: true),
        DemoAction(icon: Icons.door_front_door_outlined, label: 'Open side roll up vent', hasToggle: false),
      ],
      sensorTrends: [
        DemoTrend('HUMID', 85.0, '%', 0.85, true),
        DemoTrend('TEMP', 26.0, '°C', 0.52, false),
        DemoTrend('SOIL', 60.0, '%', 0.6, false),
      ],
    ),

    // 5. LOW HUMIDITY
    DemoScenarioData(
      title: 'Low Humidity',
      tag: 'WARNING',
      subtitle: 'Dry Air',
      videoAsset: 'assets/videos/low_humidity.mp4',
      quote: '"The air is too dry — my leaves are curling!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        DemoAction(icon: Icons.water_drop, label: 'Run Water Pump to mist lightly', hasToggle: true),
        DemoAction(icon: Icons.door_front_door_outlined, label: 'Close side roll up vent to retain moisture', hasToggle: false),
      ],
      sensorTrends: [
        DemoTrend('HUMID', 30.0, '%', 0.3, true),
        DemoTrend('TEMP', 24.0, '°C', 0.48, false),
        DemoTrend('SOIL', 55.0, '%', 0.55, false),
      ],
    ),

    // 6. HIGH LIGHT
    DemoScenarioData(
      title: 'High Light',
      tag: 'WARNING',
      subtitle: 'Light Burn',
      videoAsset: 'assets/videos/high_light.mp4',
      quote: '"The light is too intense — my leaves are scorching!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        DemoAction(icon: Icons.wb_shade, label: 'Add shade cloth', hasToggle: false),
        DemoAction(icon: Icons.door_front_door_outlined, label: 'Open side roll up vent for cooling', hasToggle: false),
      ],
      sensorTrends: [
        DemoTrend('LIGHT', 15000.0, 'lux', 0.95, true),
        DemoTrend('TEMP', 30.0, '°C', 0.6, true),
        DemoTrend('HUMID', 50.0, '%', 0.42, false),
      ],
    ),

    // 7. LOW LIGHT
    DemoScenarioData(
      title: 'Low Light',
      tag: 'WARNING',
      subtitle: 'Light Deficiency',
      videoAsset: 'assets/videos/low_light.mp4',
      quote: '"It is so dark — I cannot photosynthesize!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        DemoAction(icon: Icons.lightbulb, label: 'Check grow light placement', hasToggle: false),
        DemoAction(icon: Icons.door_front_door_outlined, label: 'Close side roll up vent to reduce light loss', hasToggle: false),
      ],
      sensorTrends: [
        DemoTrend('LIGHT', 2000.0, 'lux', 0.2, true),
        DemoTrend('TEMP', 22.0, '°C', 0.44, false),
        DemoTrend('HUMID', 60.0, '%', 0.55, false),
      ],
    ),

    // 8. HIGH MOISTURE
    DemoScenarioData(
      title: 'High Moisture',
      tag: 'WARNING',
      subtitle: 'Overwatering Risk',
      videoAsset: 'assets/videos/high_moisture.mp4',
      quote: '"My roots are drowning — too much water!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        DemoAction(icon: Icons.wind_power, label: 'Boost Ventilation Fans to dry soil', hasToggle: true),
        DemoAction(icon: Icons.air, label: 'Turn on Exhaust Fan', hasToggle: true),
        DemoAction(icon: Icons.door_front_door_outlined, label: 'Open side roll up vent for airflow', hasToggle: false),
      ],
      sensorTrends: [
        DemoTrend('SOIL', 85.0, '%', 0.85, true),
        DemoTrend('HUMID', 75.0, '%', 0.65, true),
        DemoTrend('TEMP', 24.0, '°C', 0.48, false),
      ],
    ),

    // 9. LOW MOISTURE
    DemoScenarioData(
      title: 'Low Moisture',
      tag: 'WARNING',
      subtitle: 'Drought Stress',
      videoAsset: 'assets/videos/low_moisture.mp4',
      quote: '"I am so thirsty, my leaves are wilting!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        DemoAction(icon: Icons.water_drop, label: 'Run Water Pump to irrigate', hasToggle: true),
        DemoAction(icon: Icons.door_front_door_outlined, label: 'Close side roll up vent to reduce evaporation', hasToggle: false),
      ],
      sensorTrends: [
        DemoTrend('SOIL', 18.0, '%', 0.18, true),
        DemoTrend('TEMP', 28.0, '°C', 0.56, false),
        DemoTrend('HUMID', 40.0, '%', 0.33, true),
      ],
    ),

    // 10. HIGH pH
    DemoScenarioData(
      title: 'High pH',
      tag: 'WARNING',
      subtitle: 'Alkaline Stress',
      videoAsset: 'assets/videos/high_ph.mp4',
      quote: '"My roots are burning from this alkaline!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        DemoAction(icon: Icons.science, label: 'Add pH down solution', hasToggle: false),
        DemoAction(icon: Icons.water_drop, label: 'Run Water Pump to flush with pH-balanced water', hasToggle: true),
      ],
      sensorTrends: [
        DemoTrend('pH', 8.2, '', 0.82, true),
        DemoTrend('EC', 3.5, 'mS/cm', 0.7, true),
        DemoTrend('SOIL', 50.0, '%', 0.5, false),
      ],
    ),

    // 11. LOW pH
    DemoScenarioData(
      title: 'Low pH',
      tag: 'WARNING',
      subtitle: 'Acidic Stress',
      videoAsset: 'assets/videos/low_ph.mp4',
      quote: '"The soil is too acidic — my nutrients are locked!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        DemoAction(icon: Icons.science, label: 'Add pH up solution', hasToggle: false),
        DemoAction(icon: Icons.water_drop, label: 'Run Water Pump to flush with pH-balanced water', hasToggle: true),
      ],
      sensorTrends: [
        DemoTrend('pH', 5.0, '', 0.5, true),
        DemoTrend('EC', 1.2, 'mS/cm', 0.24, false),
        DemoTrend('SOIL', 50.0, '%', 0.5, false),
      ],
    ),

    // 12. HIGH EC
    DemoScenarioData(
      title: 'High EC',
      tag: 'WARNING',
      subtitle: 'Nutrient Burn',
      videoAsset: 'assets/videos/high_ec.mp4',
      quote: '"Too much nutrients — my roots are burning!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        DemoAction(icon: Icons.water_drop, label: 'Run Water Pump to flush system with clean water', hasToggle: true),
        DemoAction(icon: Icons.science, label: 'Reduce nutrient concentration', hasToggle: false),
      ],
      sensorTrends: [
        DemoTrend('EC', 4.5, 'mS/cm', 0.9, true),
        DemoTrend('pH', 6.8, '', 0.68, false),
        DemoTrend('SOIL', 55.0, '%', 0.55, false),
      ],
    ),

    // 13. LOW EC
    DemoScenarioData(
      title: 'Low EC',
      tag: 'WARNING',
      subtitle: 'Nutrient Deficiency',
      videoAsset: 'assets/videos/low_ec.mp4',
      quote: '"I am starving — there are not enough nutrients!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        DemoAction(icon: Icons.science, label: 'Add nutrient solution', hasToggle: false),
        DemoAction(icon: Icons.water_drop, label: 'Run Water Pump to distribute nutrients', hasToggle: true),
      ],
      sensorTrends: [
        DemoTrend('EC', 0.8, 'mS/cm', 0.16, true),
        DemoTrend('pH', 6.5, '', 0.5, false),
        DemoTrend('SOIL', 48.0, '%', 0.48, false),
      ],
    ),

    // 14. NORMAL / HEALTHY
    DemoScenarioData(
      title: 'Normal / Healthy',
      tag: 'NORMAL',
      subtitle: 'Balanced Growth',
      videoAsset: 'assets/videos/norml_healthy.mp4',
      quote: '"Everything is going smoothly, keep it up!"',
      quoteColor: const Color(0xFF27AE60),
      cardColor: const Color(0xFFE8F8F5),
      borderColor: const Color(0xFF2ECC71),
      actions: [
        DemoAction(icon: Icons.check_circle, label: 'Maintain current settings', hasToggle: false),
      ],
      sensorTrends: [
        DemoTrend('TEMP', 25.0, '°C', 0.5, false),
        DemoTrend('HUMID', 65.0, '%', 0.55, false),
        DemoTrend('LIGHT', 8000.0, 'lux', 0.53, false),
        DemoTrend('SOIL', 55.0, '%', 0.55, false),
        DemoTrend('pH', 6.50, '', 0.5, false),
        DemoTrend('EC', 2.00, 'mS/cm', 0.5, false),
      ],
    ),

    // 15. THRIVING / OPTIMAL
    DemoScenarioData(
      title: 'Thriving / Optimal',
      tag: 'THRIVING',
      subtitle: 'Peak Performance',
      videoAsset: 'assets/videos/norml_healthy.mp4',
      quote: '"I am living my best life — growing strong every day!"',
      quoteColor: const Color(0xFF1E8449),
      cardColor: const Color(0xFFD5F5E3),
      borderColor: const Color(0xFF27AE60),
      actions: [
        DemoAction(icon: Icons.emoji_events, label: 'Document growth for records', hasToggle: false),
        DemoAction(icon: Icons.camera_alt, label: 'Take progress photo', hasToggle: false),
      ],
      sensorTrends: [
        DemoTrend('TEMP', 24.0, '°C', 0.48, false),
        DemoTrend('HUMID', 70.0, '%', 0.6, false),
        DemoTrend('LIGHT', 10000.0, 'lux', 0.67, false),
        DemoTrend('SOIL', 60.0, '%', 0.6, false),
        DemoTrend('pH', 6.50, '', 0.5, false),
        DemoTrend('EC', 2.50, 'mS/cm', 0.63, false),
      ],
    ),
  ];

  void _nextDemoScenario() {
    setState(() {
      _demoScenarioIndex = (_demoScenarioIndex + 1) % _demoScenarios.length;
    });
  }

  void _prevDemoScenario() {
    setState(() {
      _demoScenarioIndex = (_demoScenarioIndex - 1 + _demoScenarios.length) % _demoScenarios.length;
    });
  }

  // ── LIVE: Auto-detect scenario from real sensor data ─────
  LiveScenarioData _detectLiveScenario(AppState state) {
    final readings = state.readings;
    if (readings.isEmpty) {
      return _buildNormalScenario(state);
    }

    // Find critical readings
    final alertReadings = readings.where((r) => r.status == SensorStatus.alert).toList();
    final warningReadings = readings.where((r) => r.status == SensorStatus.warning).toList();

    if (alertReadings.length >= 2) {
      return _buildPanicScenario(state);
    }

    // Check individual sensor conditions
    for (final reading in alertReadings) {
      final condition = _detectCondition(reading);
      if (condition != null) return condition;
    }

    for (final reading in warningReadings) {
      final condition = _detectCondition(reading);
      if (condition != null) return condition;
    }

    // All normal
    if (readings.every((r) => r.status == SensorStatus.normal)) {
      return _buildThrivingScenario(state);
    }

    return _buildNormalScenario(state);
  }

  LiveScenarioData? _detectCondition(SensorReading reading) {
    final label = reading.label.toLowerCase();
    final value = reading.value;

    // Temperature
    if (label.contains('temp')) {
      if (value > 32) return _buildHighTempScenario(reading);
      if (value < 18) return _buildLowTempScenario(reading);
    }

    // Humidity
    if (label.contains('humid')) {
      if (value > 80) return _buildHighHumidityScenario(reading);
      if (value < 35) return _buildLowHumidityScenario(reading);
    }

    // Light
    if (label.contains('light')) {
      if (value > 12000) return _buildHighLightScenario(reading);
      if (value < 3000) return _buildLowLightScenario(reading);
    }

    // Moisture/Soil
    if (label.contains('soil') || label.contains('moist')) {
      if (value > 80) return _buildHighMoistureScenario(reading);
      if (value < 25) return _buildLowMoistureScenario(reading);
    }

    // pH
    if (label.contains('ph')) {
      if (value > 7.5) return _buildHighPhScenario(reading);
      if (value < 5.5) return _buildLowPhScenario(reading);
    }

    // EC
    if (label.contains('ec')) {
      if (value > 4.0) return _buildHighEcScenario(reading);
      if (value < 1.0) return _buildLowEcScenario(reading);
    }

    return null;
  }

  // ── Live scenario builders ───────────────────────────────
  LiveScenarioData _buildPanicScenario(AppState state) {
    return LiveScenarioData(
      title: 'Panic / Critical',
      tag: 'PANIC',
      subtitle: 'Emergency State',
      videoAsset: 'assets/videos/panic_critical.mp4',
      quote: '"MAYDAY MAYDAY MAYDAY — I am on the brink of death!"',
      quoteColor: const Color(0xFFC0392B),
      cardColor: const Color(0xFFFDE8E8),
      borderColor: const Color(0xFFE74C3C),
      actions: _buildLiveActions(state),
      sensorTrends: state.readings.map((r) => LiveTrend(
        label: _shortLabel(r.label),
        value: r.value,
        unit: r.unit,
        progress: _calculateProgress(r),
        isCritical: r.status == SensorStatus.alert,
      )).toList(),
    );
  }

  LiveScenarioData _buildHighTempScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'High Temperature',
      tag: 'WARNING',
      subtitle: 'Heat Stress',
      videoAsset: 'assets/videos/high_temperature.mp4',
      quote: '"It feels like an oven in here!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        LiveAction(icon: Icons.air, label: 'Turn on Exhaust Fan to vent hot air', isCritical: true),
        LiveAction(icon: Icons.wind_power, label: 'Boost Ventilation Fans', isCritical: true),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Open side roll up vent', isCritical: false),
      ],
      sensorTrends: [],
    );
  }

  LiveScenarioData _buildLowTempScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'Low Temperature',
      tag: 'WARNING',
      subtitle: 'Cold Stress',
      videoAsset: 'assets/videos/low_temperature.mp4',
      quote: '"I am freezing — my growth has stopped!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        LiveAction(icon: Icons.wind_power, label: 'Reduce Ventilation Fan speed', isCritical: false),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Close side roll up vent', isCritical: false),
      ],
      sensorTrends: [],
    );
  }

  LiveScenarioData _buildHighHumidityScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'High Humidity',
      tag: 'WARNING',
      subtitle: 'Mold Risk',
      videoAsset: 'assets/videos/high_humidity.mp4',
      quote: '"It is so humid, mold is growing on me!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        LiveAction(icon: Icons.air, label: 'Turn on Exhaust Fan to reduce humidity', isCritical: true),
        LiveAction(icon: Icons.wind_power, label: 'Boost Ventilation Fans', isCritical: true),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Open side roll up vent', isCritical: false),
      ],
      sensorTrends: [],
    );
  }

  LiveScenarioData _buildLowHumidityScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'Low Humidity',
      tag: 'WARNING',
      subtitle: 'Dry Air',
      videoAsset: 'assets/videos/low_humidity.mp4',
      quote: '"The air is too dry — my leaves are curling!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        LiveAction(icon: Icons.water_drop, label: 'Run Water Pump to mist lightly', isCritical: true),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Close side roll up vent to retain moisture', isCritical: false),
      ],
      sensorTrends: [],
    );
  }

  LiveScenarioData _buildHighLightScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'High Light',
      tag: 'WARNING',
      subtitle: 'Light Burn',
      videoAsset: 'assets/videos/high_light.mp4',
      quote: '"The light is too intense — my leaves are scorching!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        LiveAction(icon: Icons.wb_shade, label: 'Add shade cloth', isCritical: false),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Open side roll up vent for cooling', isCritical: false),
      ],
      sensorTrends: [],
    );
  }

  LiveScenarioData _buildLowLightScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'Low Light',
      tag: 'WARNING',
      subtitle: 'Light Deficiency',
      videoAsset: 'assets/videos/low_light.mp4',
      quote: '"It is so dark — I cannot photosynthesize!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        LiveAction(icon: Icons.lightbulb, label: 'Check grow light placement', isCritical: false),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Close side roll up vent to reduce light loss', isCritical: false),
      ],
      sensorTrends: [],
    );
  }

  LiveScenarioData _buildHighMoistureScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'High Moisture',
      tag: 'WARNING',
      subtitle: 'Overwatering Risk',
      videoAsset: 'assets/videos/high_moisture.mp4',
      quote: '"My roots are drowning — too much water!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        LiveAction(icon: Icons.wind_power, label: 'Boost Ventilation Fans to dry soil', isCritical: true),
        LiveAction(icon: Icons.air, label: 'Turn on Exhaust Fan', isCritical: true),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Open side roll up vent for airflow', isCritical: false),
      ],
      sensorTrends: [],
    );
  }

  LiveScenarioData _buildLowMoistureScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'Low Moisture',
      tag: 'WARNING',
      subtitle: 'Drought Stress',
      videoAsset: 'assets/videos/low_moisture.mp4',
      quote: '"I am so thirsty, my leaves are wilting!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        LiveAction(icon: Icons.water_drop, label: 'Run Water Pump to irrigate', isCritical: true),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Close side roll up vent to reduce evaporation', isCritical: false),
      ],
      sensorTrends: [],
    );
  }

  LiveScenarioData _buildHighPhScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'High pH',
      tag: 'WARNING',
      subtitle: 'Alkaline Stress',
      videoAsset: 'assets/videos/high_ph.mp4',
      quote: '"My roots are burning from this alkaline!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        LiveAction(icon: Icons.science, label: 'Add pH down solution', isCritical: false),
        LiveAction(icon: Icons.water_drop, label: 'Run Water Pump to flush with pH-balanced water', isCritical: true),
      ],
      sensorTrends: [],
    );
  }

  LiveScenarioData _buildLowPhScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'Low pH',
      tag: 'WARNING',
      subtitle: 'Acidic Stress',
      videoAsset: 'assets/videos/low_ph.mp4',
      quote: '"The soil is too acidic — my nutrients are locked!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        LiveAction(icon: Icons.science, label: 'Add pH up solution', isCritical: false),
        LiveAction(icon: Icons.water_drop, label: 'Run Water Pump to flush with pH-balanced water', isCritical: true),
      ],
      sensorTrends: [],
    );
  }

  LiveScenarioData _buildHighEcScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'High EC',
      tag: 'WARNING',
      subtitle: 'Nutrient Burn',
      videoAsset: 'assets/videos/high_ec.mp4',
      quote: '"Too much nutrients — my roots are burning!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        LiveAction(icon: Icons.water_drop, label: 'Run Water Pump to flush system with clean water', isCritical: true),
        LiveAction(icon: Icons.science, label: 'Reduce nutrient concentration', isCritical: false),
      ],
      sensorTrends: [],
    );
  }

  LiveScenarioData _buildLowEcScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'Low EC',
      tag: 'WARNING',
      subtitle: 'Nutrient Deficiency',
      videoAsset: 'assets/videos/low_ec.mp4',
      quote: '"I am starving — there are not enough nutrients!"',
      quoteColor: const Color(0xFFD35400),
      cardColor: const Color(0xFFFEF5E7),
      borderColor: const Color(0xFFF39C12),
      actions: [
        LiveAction(icon: Icons.science, label: 'Add nutrient solution', isCritical: false),
        LiveAction(icon: Icons.water_drop, label: 'Run Water Pump to distribute nutrients', isCritical: true),
      ],
      sensorTrends: [],
    );
  }

  LiveScenarioData _buildNormalScenario(AppState state) {
    return LiveScenarioData(
      title: 'Normal / Healthy',
      tag: 'NORMAL',
      subtitle: 'Balanced Growth',
      videoAsset: 'assets/videos/norml_healthy.mp4',
      quote: '"Everything is going smoothly, keep it up!"',
      quoteColor: const Color(0xFF27AE60),
      cardColor: const Color(0xFFE8F8F5),
      borderColor: const Color(0xFF2ECC71),
      actions: [
        LiveAction(icon: Icons.check_circle, label: 'Maintain current settings', isCritical: false),
      ],
      sensorTrends: state.readings.map((r) => LiveTrend(
        label: _shortLabel(r.label),
        value: r.value,
        unit: r.unit,
        progress: _calculateProgress(r),
        isCritical: r.status == SensorStatus.alert,
      )).toList(),
    );
  }

  LiveScenarioData _buildThrivingScenario(AppState state) {
    return LiveScenarioData(
      title: 'Thriving / Optimal',
      tag: 'THRIVING',
      subtitle: 'Peak Performance',
      videoAsset: 'assets/videos/norml_healthy.mp4',
      quote: '"I am living my best life — growing strong every day!"',
      quoteColor: const Color(0xFF1E8449),
      cardColor: const Color(0xFFD5F5E3),
      borderColor: const Color(0xFF27AE60),
      actions: [
        LiveAction(icon: Icons.emoji_events, label: 'Document growth for records', isCritical: false),
        LiveAction(icon: Icons.camera_alt, label: 'Take progress photo', isCritical: false),
      ],
      sensorTrends: state.readings.map((r) => LiveTrend(
        label: _shortLabel(r.label),
        value: r.value,
        unit: r.unit,
        progress: _calculateProgress(r),
        isCritical: r.status == SensorStatus.alert,
      )).toList(),
    );
  }

  // ── Helpers ──────────────────────────────────────────────
  List<LiveAction> _buildLiveActions(AppState state) {
    final actions = <LiveAction>[];
    for (final reading in state.readings) {
      if (reading.status == SensorStatus.alert) {
        final label = reading.label.toLowerCase();
        if (label.contains('temp') && reading.value > 32) {
          actions.add(LiveAction(icon: Icons.air, label: 'Turn on Exhaust Fan to vent hot air', isCritical: true));
          actions.add(LiveAction(icon: Icons.wind_power, label: 'Boost Ventilation Fans', isCritical: true));
        }
        if (label.contains('temp') && reading.value < 18) {
          actions.add(LiveAction(icon: Icons.wind_power, label: 'Reduce Ventilation Fan speed', isCritical: false));
        }
        if ((label.contains('soil') || label.contains('moist')) && reading.value < 25) {
          actions.add(LiveAction(icon: Icons.water_drop, label: 'Run Water Pump to irrigate', isCritical: true));
        }
        if ((label.contains('soil') || label.contains('moist')) && reading.value > 80) {
          actions.add(LiveAction(icon: Icons.wind_power, label: 'Boost Ventilation Fans to dry soil', isCritical: true));
        }
      }
    }
    if (actions.isEmpty) {
      actions.add(LiveAction(icon: Icons.check_circle, label: 'Maintain current settings', isCritical: false));
    }
    return actions;
  }

  String _shortLabel(String label) {
    if (label.toLowerCase().contains('temp')) return 'TEMP';
    if (label.toLowerCase().contains('humid')) return 'HUMID';
    if (label.toLowerCase().contains('light')) return 'LIGHT';
    if (label.toLowerCase().contains('soil') || label.toLowerCase().contains('moist')) return 'SOIL';
    if (label.toLowerCase().contains('ph')) return 'pH';
    if (label.toLowerCase().contains('ec')) return 'EC';
    return label.toUpperCase();
  }

  double _calculateProgress(SensorReading reading) {
    // Simple progress calculation based on value vs typical range
    final label = reading.label.toLowerCase();
    double max = 100;
    if (label.contains('temp')) max = 50;
    else if (label.contains('humid')) max = 100;
    else if (label.contains('light')) max = 15000;
    else if (label.contains('soil') || label.contains('moist')) max = 100;
    else if (label.contains('ph')) max = 14;
    else if (label.contains('ec')) max = 5;
    return (reading.value / max).clamp(0.0, 1.0);
  }

  // ── Get status counts based on scenario tag ──────────────
  (int stableCount, int alertCount) _getStatusCounts(String tag) {
    switch (tag) {
      case 'PANIC':
        return (4, 2); // 4 stable, 2 critical
      case 'WARNING':
        return (5, 1); // 5 stable, 1 warning
      case 'NORMAL':
        return (6, 0); // All stable
      case 'THRIVING':
        return (6, 0); // All stable
      default:
        return (5, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final liveScenario = _detectLiveScenario(state);
    final demoScenario = _demoScenarios[_demoScenarioIndex];
    final currentScenario = _isDemoMode ? demoScenario : liveScenario;

    return Scaffold(
      backgroundColor: AppTheme.bg0,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── TOGGLE ──────────────────────────────────────
            _buildModeToggle(),

            // ── DEMO: SCENARIO NAVIGATOR ────────────────────
            if (_isDemoMode) _buildDemoNavigator(demoScenario),

            // ── SCENE CARD ──────────────────────────────────
            _buildSceneCard(currentScenario),

            // ── RECOMMENDED ACTIONS ─────────────────────────
            _buildActions(currentScenario),

            // ── SENSOR TRENDS ────────────────────────────────
            _buildSensorTrends(currentScenario, state),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MODE TOGGLE
  // ═══════════════════════════════════════════════════════════
  Widget _buildModeToggle() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.bg1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isDemoMode = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isDemoMode ? AppTheme.olive : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sensors,
                          size: 16,
                          color: !_isDemoMode ? Colors.white : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: !_isDemoMode ? Colors.white : AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isDemoMode = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isDemoMode ? AppTheme.statusWarning : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam,
                          size: 16,
                          color: _isDemoMode ? Colors.white : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'DEMO',
                          style: TextStyle(
                            color: _isDemoMode ? Colors.white : AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DEMO NAVIGATOR
  // ═══════════════════════════════════════════════════════════
  Widget _buildDemoNavigator(DemoScenarioData scenario) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.bg1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _prevDemoScenario,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.bg2,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: AppTheme.ink,
                        size: 24,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: scenario.borderColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'SCENARIO',
                          style: TextStyle(
                            color: scenario.borderColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        scenario.title,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scenario.subtitle,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _nextDemoScenario,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.bg2,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: AppTheme.ink,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_demoScenarios.length, (index) {
                  final isActive = index == _demoScenarioIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 20 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isActive ? scenario.borderColor : AppTheme.divider,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${_demoScenarioIndex + 1} / ${_demoScenarios.length}',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SCENE CARD WITH STATUS ICONS
  // ═══════════════════════════════════════════════════════════
  Widget _buildSceneCard(dynamic scenario) {
    final title = scenario is LiveScenarioData ? scenario.title : (scenario as DemoScenarioData).title;
    final tag = scenario is LiveScenarioData ? scenario.tag : (scenario as DemoScenarioData).tag;
    final subtitle = scenario is LiveScenarioData ? scenario.subtitle : (scenario as DemoScenarioData).subtitle;
    final videoAsset = scenario is LiveScenarioData ? scenario.videoAsset : (scenario as DemoScenarioData).videoAsset;
    final quote = scenario is LiveScenarioData ? scenario.quote : (scenario as DemoScenarioData).quote;
    final quoteColor = scenario is LiveScenarioData ? scenario.quoteColor : (scenario as DemoScenarioData).quoteColor;
    final cardColor = scenario is LiveScenarioData ? scenario.cardColor : (scenario as DemoScenarioData).cardColor;
    final borderColor = scenario is LiveScenarioData ? scenario.borderColor : (scenario as DemoScenarioData).borderColor;

    // Determine status counts based on tag
    final (stableCount, alertCount) = _getStatusCounts(tag);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── STATUS HEADER WITH ICONS ─────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    // Left accent bar + Title
                    Row(
                      children: [
                        // Vertical accent bar
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Title text
                        Text(
                          tag,
                          style: TextStyle(
                            color: borderColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // ── STATUS ICONS ─────────────────────
                    // Stable/Optimal count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: const Color(0xFF27AE60),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$stableCount',
                            style: const TextStyle(
                              color: Color(0xFF27AE60),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Warning/Danger count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: alertCount > 0
                            ? const Color(0xFFE74C3C).withOpacity(0.15)
                            : const Color(0xFFF39C12).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            alertCount > 0 ? Icons.error : Icons.warning_amber,
                            color: alertCount > 0
                                ? const Color(0xFFE74C3C)
                                : const Color(0xFFF39C12),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$alertCount',
                            style: TextStyle(
                              color: alertCount > 0
                                  ? const Color(0xFFE74C3C)
                                  : const Color(0xFFF39C12),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── SUBTITLE ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 4, 16, 0),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // VIDEO PLAYER
              Padding(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ScenarioVideoPlayer(
                    key: ValueKey(videoAsset),
                    videoAsset: videoAsset,
                  ),
                ),
              ),

              // Quote
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    quote,
                    style: TextStyle(
                      color: quoteColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════
  Widget _buildActions(dynamic scenario) {
    final actions = scenario is LiveScenarioData ? scenario.actions : (scenario as DemoScenarioData).actions;
    final borderColor = scenario is LiveScenarioData ? scenario.borderColor : (scenario as DemoScenarioData).borderColor;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'RECOMMENDED ACTIONS',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const Expanded(
                  child: Divider(
                    color: AppTheme.divider,
                    indent: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...actions.map((action) => _buildActionCard(action, borderColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(dynamic action, Color borderColor) {
    final icon = action is LiveAction ? action.icon : (action as DemoAction).icon;
    final label = action is LiveAction ? action.label : (action as DemoAction).label;
    final isCritical = action is LiveAction ? action.isCritical : (action as DemoAction).isCritical;
    final hasToggle = action is DemoAction ? action.hasToggle : false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical
              ? const Color(0xFFE74C3C).withOpacity(0.3)
              : AppTheme.divider,
          width: isCritical ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCritical
                  ? const Color(0xFFE74C3C).withOpacity(0.15)
                  : AppTheme.bg2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isCritical ? const Color(0xFFE74C3C) : AppTheme.olive,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          if (hasToggle) ...[
            const SizedBox(width: 12),
            _ActionToggle(scenarioColor: borderColor),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SENSOR TRENDS
  // ═══════════════════════════════════════════════════════════
  Widget _buildSensorTrends(dynamic scenario, AppState state) {
    final borderColor = scenario is LiveScenarioData ? scenario.borderColor : (scenario as DemoScenarioData).borderColor;

    // Get trends: live uses real data, demo uses static
    final trends = _isDemoMode
        ? (scenario as DemoScenarioData).sensorTrends
        : state.readings.map((r) => LiveTrend(
            label: _shortLabel(r.label),
            value: r.value,
            unit: r.unit,
            progress: _calculateProgress(r),
            isCritical: r.status == SensorStatus.alert,
          )).toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'SENSOR TRENDS',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const Expanded(
                  child: Divider(
                    color: AppTheme.divider,
                    indent: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bg1,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                children: trends.map((trend) => _buildTrendRow(trend)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendRow(dynamic trend) {
    final label = trend is LiveTrend ? trend.label : (trend as DemoTrend).label;
    final value = trend is LiveTrend ? trend.value : (trend as DemoTrend).value;
    final unit = trend is LiveTrend ? trend.unit : (trend as DemoTrend).unit;
    final progress = trend is LiveTrend ? trend.progress : (trend as DemoTrend).progress;
    final isCritical = trend is LiveTrend ? trend.isCritical : (trend as DemoTrend).isCritical;

    IconData getIcon(String label) {
      switch (label) {
        case 'TEMP': return Icons.thermostat;
        case 'HUMID': return Icons.water_drop;
        case 'LIGHT': return Icons.wb_sunny;
        case 'SOIL': return Icons.grass;
        case 'pH': return Icons.science;
        case 'EC': return Icons.electric_bolt;
        default: return Icons.sensors;
      }
    }

    Color getIconColor(String label) {
      switch (label) {
        case 'TEMP': return const Color(0xFFE74C3C);
        case 'HUMID': return const Color(0xFF27AE60);
        case 'LIGHT': return const Color(0xFFF39C12);
        case 'SOIL': return const Color(0xFFE74C3C);
        case 'pH': return const Color(0xFF27AE60);
        case 'EC': return const Color(0xFF27AE60);
        default: return AppTheme.textMuted;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(getIcon(label), color: getIconColor(label), size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.bg2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCritical ? const Color(0xFFE74C3C) : const Color(0xFF27AE60),
                ),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)} $unit',
            style: TextStyle(
              color: isCritical ? const Color(0xFFE74C3C) : AppTheme.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCritical ? const Color(0xFFE74C3C) : const Color(0xFF27AE60),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════

// ── Live Models ──────────────────────────────────────────
class LiveScenarioData {
  final String title;
  final String tag;
  final String subtitle;
  final String videoAsset;
  final String quote;
  final Color quoteColor;
  final Color cardColor;
  final Color borderColor;
  final List<LiveAction> actions;
  final List<LiveTrend> sensorTrends;

  LiveScenarioData({
    required this.title,
    required this.tag,
    required this.subtitle,
    required this.videoAsset,
    required this.quote,
    required this.quoteColor,
    required this.cardColor,
    required this.borderColor,
    required this.actions,
    required this.sensorTrends,
  });
}

class LiveAction {
  final IconData icon;
  final String label;
  final bool isCritical;

  LiveAction({
    required this.icon,
    required this.label,
    this.isCritical = false,
  });
}

class LiveTrend {
  final String label;
  final double value;
  final String unit;
  final double progress;
  final bool isCritical;

  LiveTrend({
    required this.label,
    required this.value,
    required this.unit,
    required this.progress,
    required this.isCritical,
  });
}

// ── Demo Models ──────────────────────────────────────────
class DemoScenarioData {
  final String title;
  final String tag;
  final String subtitle;
  final String videoAsset;
  final String quote;
  final Color quoteColor;
  final Color cardColor;
  final Color borderColor;
  final List<DemoAction> actions;
  final List<DemoTrend> sensorTrends;

  DemoScenarioData({
    required this.title,
    required this.tag,
    required this.subtitle,
    required this.videoAsset,
    required this.quote,
    required this.quoteColor,
    required this.cardColor,
    required this.borderColor,
    required this.actions,
    required this.sensorTrends,
  });
}

class DemoAction {
  final IconData icon;
  final String label;
  final bool hasToggle;
  final bool isCritical;

  DemoAction({
    required this.icon,
    required this.label,
    this.hasToggle = false,
    this.isCritical = false,
  });
}

class DemoTrend {
  final String label;
  final double value;
  final String unit;
  final double progress;
  final bool isCritical;

  DemoTrend(this.label, this.value, this.unit, this.progress, this.isCritical);
}

// ═══════════════════════════════════════════════════════════
// ACTION TOGGLE WIDGET
// ═══════════════════════════════════════════════════════════

class _ActionToggle extends StatefulWidget {
  final Color scenarioColor;

  const _ActionToggle({required this.scenarioColor});

  @override
  State<_ActionToggle> createState() => _ActionToggleState();
}

class _ActionToggleState extends State<_ActionToggle> {
  int _mode = 1; // 0 = OFF, 1 = AUTO, 2 = ON

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            label: 'OFF',
            isSelected: _mode == 0,
            onTap: () => setState(() => _mode = 0),
          ),
          _ToggleButton(
            label: 'AUTO',
            isSelected: _mode == 1,
            isAccent: true,
            accentColor: widget.scenarioColor,
            onTap: () => setState(() => _mode = 1),
          ),
          _ToggleButton(
            label: 'ON',
            isSelected: _mode == 2,
            onTap: () => setState(() => _mode = 2),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isAccent;
  final Color? accentColor;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    this.isAccent = false,
    this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isAccent ? (accentColor ?? AppTheme.olive).withOpacity(0.2) : AppTheme.bg1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected && !isAccent
              ? Border.all(color: AppTheme.divider)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isAccent ? (accentColor ?? AppTheme.olive) : AppTheme.ink)
                : AppTheme.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}