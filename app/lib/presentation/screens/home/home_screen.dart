// home_screen.dart
//
// Redesigned against the Automato Design System ("Living Minimalist"):
// soft shadows instead of heavy borders, glassmorphic hero card, 24px
// container radius, 8pt spacing grid, Inter type scale.

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:automato/domain/models/sensor_data.dart';
import 'package:automato/presentation/providers/sensor_provider.dart';
import 'package:automato/presentation/widgets/scenario_video_player.dart';

// ═══════════════════════════════════════════════════════════
// DESIGN TOKENS — generated from Automato Design System
// ═══════════════════════════════════════════════════════════

class AutoColors {
  AutoColors._();
  static const surface = Color(0xFFFCF9F8);
  static const surfaceDim = Color(0xFFDCD9D9);
  static const surfaceBright = Color(0xFFFCF9F8);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF6F3F2);
  static const surfaceContainer = Color(0xFFF0EDED);
  static const surfaceContainerHigh = Color(0xFFEAE7E7);
  static const surfaceContainerHighest = Color(0xFFE5E2E1);
  static const onSurface = Color(0xFF1B1C1C);
  static const onSurfaceVariant = Color(0xFF3F4A3C);
  static const inverseSurface = Color(0xFF303030);
  static const inverseOnSurface = Color(0xFFF3F0EF);
  static const outline = Color(0xFF6F7A6B);
  static const outlineVariant = Color(0xFFBECAB9);
  static const primary = Color(0xFF006E1C);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF4CAF50);
  static const onPrimaryContainer = Color(0xFF003C0B);
  static const inversePrimary = Color(0xFF78DC77);
  static const secondary = Color(0xFF5C5F60);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFE1E3E4);
  static const onSecondaryContainer = Color(0xFF626566);
  static const tertiary = Color(0xFF556158);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF929E94);
  static const onTertiaryContainer = Color(0xFF2A352D);
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const background = Color(0xFFFCF9F8);
  static const onBackground = Color(0xFF1B1C1C);
  static const surfaceVariant = Color(0xFFE5E2E1);
}

class AutoText {
  AutoText._();
  static const String family = 'Inter';

  static const displayLg = TextStyle(fontFamily: family, fontSize: 48, fontWeight: FontWeight.w700, height: 56 / 48, letterSpacing: -0.96, color: AutoColors.onSurface);
  static const headlineLg = TextStyle(fontFamily: family, fontSize: 32, fontWeight: FontWeight.w600, height: 40 / 32, letterSpacing: -0.32, color: AutoColors.onSurface);
  static const headlineMd = TextStyle(fontFamily: family, fontSize: 24, fontWeight: FontWeight.w600, height: 32 / 24, color: AutoColors.onSurface);
  static const bodyLg = TextStyle(fontFamily: family, fontSize: 18, fontWeight: FontWeight.w400, height: 28 / 18, color: AutoColors.onSurface);
  static const bodyMd = TextStyle(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16, color: AutoColors.onSurface);
  static const labelMd = TextStyle(fontFamily: family, fontSize: 14, fontWeight: FontWeight.w500, height: 20 / 14, letterSpacing: 0.14, color: AutoColors.onSurfaceVariant);
  static const labelSm = TextStyle(fontFamily: family, fontSize: 12, fontWeight: FontWeight.w600, height: 16 / 12, color: AutoColors.onSurfaceVariant);
}

class AutoRadius {
  AutoRadius._();
  static const double sm = 4;
  static const double base = 8; // input fields
  static const double md = 12;
  static const double lg = 16; // buttons (medium), action cards
  static const double xl = 24; // primary container cards
  static const double buttonLg = 20;
  static const double full = 999;
}

class AutoSpace {
  AutoSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double containerPadding = 24;
  static const double gutter = 16;
}

class AutoShadow {
  AutoShadow._();
  // Ambient shadow — floats cards above the surface without a border.
  static List<BoxShadow> get card => [
        BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 20, offset: const Offset(0, 4)),
      ];
  static List<BoxShadow> get elevated => [
        BoxShadow(color: Colors.black.withValues(alpha:0.08), blurRadius: 40, offset: const Offset(0, 12)),
      ];
}

/// Semantic status colors. PANIC/ERROR and healthy greens come straight
/// from the design system; WARNING is the one addition the token file
/// didn't define, tuned to sit naturally between the sage tertiary and
/// the red error tone.
class AutoStatus {
  AutoStatus._();
  static const warning = Color(0xFF8A5A00);

  static Color tagColor(String tag) {
    switch (tag) {
      case 'PANIC':
        return AutoColors.error;
      case 'WARNING':
        return warning;
      case 'THRIVING':
        return AutoColors.primary;
      case 'NORMAL':
      default:
        return AutoColors.tertiary;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// HOME SCREEN — Live/Demo Toggle with Scene Card, Actions, Trends
// ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int _demoScenarioIndex = 0;

  final List<DemoScenarioData> _demoScenarios = [
    // 1. PANIC / CRITICAL
    DemoScenarioData(
      title: 'Panic / Critical',
      tag: 'PANIC',
      subtitle: 'Emergency State',
      videoAsset: 'assets/videos/panic_critical.mp4',
      quote: '"MAYDAY MAYDAY MAYDAY — I am on the brink of death!"',
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

  @override
  void initState() {
    super.initState();
    // Tab controller to handle the horizontal swiping between Live and Demo
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

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
  LiveScenarioData _detectLiveScenario(List<SensorReading> readings) {
    if (readings.isEmpty) {
      return _buildNormalScenario(readings);
    }

    final alertReadings = readings.where((r) => r.status == SensorStatus.alert).toList();
    final warningReadings = readings.where((r) => r.status == SensorStatus.warning).toList();

    if (alertReadings.length >= 2) {
      return _buildPanicScenario(readings);
    }

    for (final reading in alertReadings) {
      final condition = _detectCondition(reading);
      if (condition != null) return condition;
    }

    for (final reading in warningReadings) {
      final condition = _detectCondition(reading);
      if (condition != null) return condition;
    }

    if (readings.every((r) => r.status == SensorStatus.normal)) {
      return _buildThrivingScenario(readings);
    }

    return _buildNormalScenario(readings);
  }

  LiveScenarioData? _detectCondition(SensorReading reading) {
    final label = reading.label.toLowerCase();
    final value = reading.value;

    if (label.contains('temp')) {
      if (value > 32) return _buildHighTempScenario(reading);
      if (value < 18) return _buildLowTempScenario(reading);
    }
    if (label.contains('humid')) {
      if (value > 80) return _buildHighHumidityScenario(reading);
      if (value < 35) return _buildLowHumidityScenario(reading);
    }
    if (label.contains('light')) {
      if (value > 12000) return _buildHighLightScenario(reading);
      if (value < 3000) return _buildLowLightScenario(reading);
    }
    if (label.contains('soil') || label.contains('moist')) {
      if (value > 80) return _buildHighMoistureScenario(reading);
      if (value < 25) return _buildLowMoistureScenario(reading);
    }
    if (label.contains('ph')) {
      if (value > 7.5) return _buildHighPhScenario(reading);
      if (value < 5.5) return _buildLowPhScenario(reading);
    }
    if (label.contains('ec')) {
      if (value > 4.0) return _buildHighEcScenario(reading);
      if (value < 1.0) return _buildLowEcScenario(reading);
    }
    return null;
  }

  // ── Live scenario builders ───────────────────────────────
  LiveScenarioData _buildPanicScenario(List<SensorReading> readings) {
    return LiveScenarioData(
      title: 'Panic / Critical',
      tag: 'PANIC',
      subtitle: 'Emergency State',
      videoAsset: 'assets/videos/panic_critical.mp4',
      quote: '"MAYDAY MAYDAY MAYDAY — I am on the brink of death!"',
      actions: _buildLiveActions(readings),
      sensorTrends: readings
          .map((r) => LiveTrend(
                label: _shortLabel(r.label),
                value: r.value,
                unit: r.unit,
                progress: _calculateProgress(r),
                isCritical: r.status == SensorStatus.alert,
              ))
          .toList(),
    );
  }

  LiveScenarioData _buildHighTempScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'High Temperature',
      tag: 'WARNING',
      subtitle: 'Heat Stress',
      videoAsset: 'assets/videos/high_temperature.mp4',
      quote: '"It feels like an oven in here!"',
      actions: [
        LiveAction(icon: Icons.air, label: 'Turn on Exhaust Fan to vent hot air', isCritical: true),
        LiveAction(icon: Icons.wind_power, label: 'Boost Ventilation Fans', isCritical: true),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Open side roll up vent', isCritical: false),
      ],
      sensorTrends: const [],
    );
  }

  LiveScenarioData _buildLowTempScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'Low Temperature',
      tag: 'WARNING',
      subtitle: 'Cold Stress',
      videoAsset: 'assets/videos/low_temperature.mp4',
      quote: '"I am freezing — my growth has stopped!"',
      actions: [
        LiveAction(icon: Icons.wind_power, label: 'Reduce Ventilation Fan speed', isCritical: false),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Close side roll up vent', isCritical: false),
      ],
      sensorTrends: const [],
    );
  }

  LiveScenarioData _buildHighHumidityScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'High Humidity',
      tag: 'WARNING',
      subtitle: 'Mold Risk',
      videoAsset: 'assets/videos/high_humidity.mp4',
      quote: '"It is so humid, mold is growing on me!"',
      actions: [
        LiveAction(icon: Icons.air, label: 'Turn on Exhaust Fan to reduce humidity', isCritical: true),
        LiveAction(icon: Icons.wind_power, label: 'Boost Ventilation Fans', isCritical: true),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Open side roll up vent', isCritical: false),
      ],
      sensorTrends: const [],
    );
  }

  LiveScenarioData _buildLowHumidityScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'Low Humidity',
      tag: 'WARNING',
      subtitle: 'Dry Air',
      videoAsset: 'assets/videos/low_humidity.mp4',
      quote: '"The air is too dry — my leaves are curling!"',
      actions: [
        LiveAction(icon: Icons.water_drop, label: 'Run Water Pump to mist lightly', isCritical: true),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Close side roll up vent to retain moisture', isCritical: false),
      ],
      sensorTrends: const [],
    );
  }

  LiveScenarioData _buildHighLightScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'High Light',
      tag: 'WARNING',
      subtitle: 'Light Burn',
      videoAsset: 'assets/videos/high_light.mp4',
      quote: '"The light is too intense — my leaves are scorching!"',
      actions: [
        LiveAction(icon: Icons.wb_shade, label: 'Add shade cloth', isCritical: false),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Open side roll up vent for cooling', isCritical: false),
      ],
      sensorTrends: const [],
    );
  }

  LiveScenarioData _buildLowLightScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'Low Light',
      tag: 'WARNING',
      subtitle: 'Light Deficiency',
      videoAsset: 'assets/videos/low_light.mp4',
      quote: '"It is so dark — I cannot photosynthesize!"',
      actions: [
        LiveAction(icon: Icons.lightbulb, label: 'Check grow light placement', isCritical: false),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Close side roll up vent to reduce light loss', isCritical: false),
      ],
      sensorTrends: const [],
    );
  }

  LiveScenarioData _buildHighMoistureScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'High Moisture',
      tag: 'WARNING',
      subtitle: 'Overwatering Risk',
      videoAsset: 'assets/videos/high_moisture.mp4',
      quote: '"My roots are drowning — too much water!"',
      actions: [
        LiveAction(icon: Icons.wind_power, label: 'Boost Ventilation Fans to dry soil', isCritical: true),
        LiveAction(icon: Icons.air, label: 'Turn on Exhaust Fan', isCritical: true),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Open side roll up vent for airflow', isCritical: false),
      ],
      sensorTrends: const [],
    );
  }

  LiveScenarioData _buildLowMoistureScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'Low Moisture',
      tag: 'WARNING',
      subtitle: 'Drought Stress',
      videoAsset: 'assets/videos/low_moisture.mp4',
      quote: '"I am so thirsty, my leaves are wilting!"',
      actions: [
        LiveAction(icon: Icons.water_drop, label: 'Run Water Pump to irrigate', isCritical: true),
        LiveAction(icon: Icons.door_front_door_outlined, label: 'Close side roll up vent to reduce evaporation', isCritical: false),
      ],
      sensorTrends: const [],
    );
  }

  LiveScenarioData _buildHighPhScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'High pH',
      tag: 'WARNING',
      subtitle: 'Alkaline Stress',
      videoAsset: 'assets/videos/high_ph.mp4',
      quote: '"My roots are burning from this alkaline!"',
      actions: [
        LiveAction(icon: Icons.science, label: 'Add pH down solution', isCritical: false),
        LiveAction(icon: Icons.water_drop, label: 'Run Water Pump to flush with pH-balanced water', isCritical: true),
      ],
      sensorTrends: const [],
    );
  }

  LiveScenarioData _buildLowPhScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'Low pH',
      tag: 'WARNING',
      subtitle: 'Acidic Stress',
      videoAsset: 'assets/videos/low_ph.mp4',
      quote: '"The soil is too acidic — my nutrients are locked!"',
      actions: [
        LiveAction(icon: Icons.science, label: 'Add pH up solution', isCritical: false),
        LiveAction(icon: Icons.water_drop, label: 'Run Water Pump to flush with pH-balanced water', isCritical: true),
      ],
      sensorTrends: const [],
    );
  }

  LiveScenarioData _buildHighEcScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'High EC',
      tag: 'WARNING',
      subtitle: 'Nutrient Burn',
      videoAsset: 'assets/videos/high_ec.mp4',
      quote: '"Too much nutrients — my roots are burning!"',
      actions: [
        LiveAction(icon: Icons.water_drop, label: 'Run Water Pump to flush system with clean water', isCritical: true),
        LiveAction(icon: Icons.science, label: 'Reduce nutrient concentration', isCritical: false),
      ],
      sensorTrends: const [],
    );
  }

  LiveScenarioData _buildLowEcScenario(SensorReading reading) {
    return LiveScenarioData(
      title: 'Low EC',
      tag: 'WARNING',
      subtitle: 'Nutrient Deficiency',
      videoAsset: 'assets/videos/low_ec.mp4',
      quote: '"I am starving — there are not enough nutrients!"',
      actions: [
        LiveAction(icon: Icons.science, label: 'Add nutrient solution', isCritical: false),
        LiveAction(icon: Icons.water_drop, label: 'Run Water Pump to distribute nutrients', isCritical: true),
      ],
      sensorTrends: const [],
    );
  }

  LiveScenarioData _buildNormalScenario(List<SensorReading> readings) {
    return LiveScenarioData(
      title: 'Normal / Healthy',
      tag: 'NORMAL',
      subtitle: 'Balanced Growth',
      videoAsset: 'assets/videos/norml_healthy.mp4',
      quote: '"Everything is going smoothly, keep it up!"',
      actions: [
        LiveAction(icon: Icons.check_circle, label: 'Maintain current settings', isCritical: false),
      ],
      sensorTrends: readings
          .map((r) => LiveTrend(
                label: _shortLabel(r.label),
                value: r.value,
                unit: r.unit,
                progress: _calculateProgress(r),
                isCritical: r.status == SensorStatus.alert,
              ))
          .toList(),
    );
  }

  LiveScenarioData _buildThrivingScenario(List<SensorReading> readings) {
    return LiveScenarioData(
      title: 'Thriving / Optimal',
      tag: 'THRIVING',
      subtitle: 'Peak Performance',
      videoAsset: 'assets/videos/norml_healthy.mp4',
      quote: '"I am living my best life — growing strong every day!"',
      actions: [
        LiveAction(icon: Icons.emoji_events, label: 'Document growth for records', isCritical: false),
        LiveAction(icon: Icons.camera_alt, label: 'Take progress photo', isCritical: false),
      ],
      sensorTrends: readings
          .map((r) => LiveTrend(
                label: _shortLabel(r.label),
                value: r.value,
                unit: r.unit,
                progress: _calculateProgress(r),
                isCritical: r.status == SensorStatus.alert,
              ))
          .toList(),
    );
  }

  // ── Helpers ──────────────────────────────────────────────
  List<LiveAction> _buildLiveActions(List<SensorReading> readings) {
    final actions = <LiveAction>[];
    for (final reading in readings) {
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
    final label = reading.label.toLowerCase();
    double max = 100;
    if (label.contains('temp')) {
      max = 50;
    } else if (label.contains('humid')) {
      max = 100;
    } else if (label.contains('light')) {
      max = 15000;
    } else if (label.contains('soil') || label.contains('moist')) {
      max = 100;
    } else if (label.contains('ph')) {
      max = 14;
    } else if (label.contains('ec')) {
      max = 5;
    }
    return (reading.value / max).clamp(0.0, 1.0);
  }

  (int stableCount, int alertCount) _getStatusCounts(String tag) {
    switch (tag) {
      case 'PANIC':
        return (4, 2);
      case 'WARNING':
        return (5, 1);
      case 'NORMAL':
        return (6, 0);
      case 'THRIVING':
        return (6, 0);
      default:
        return (5, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensorProvider = context.watch<SensorProvider>();
    final readings = sensorProvider.readings;

    return Scaffold(
      backgroundColor: AutoColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildModeToggle(),
            const SizedBox(height: 8),
            
            // The swipable content area
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildLiveTab(readings), // Page 1 (LIVE)
                  _buildDemoTab(readings), // Page 2 (DEMO)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MODE TOGGLE (Styled like Camera Screen Tabs)
  // ═══════════════════════════════════════════════════════════

  Widget _buildModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E2DC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFF132F28),
          unselectedLabelColor: const Color(0xFF737A76),
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: -0.1,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "Live"),
            Tab(text: "Demo"),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SWIPABLE TABS CONTENT
  // ═══════════════════════════════════════════════════════════

  Widget _buildLiveTab(List<SensorReading> readings) {
    final liveScenario = _detectLiveScenario(readings);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSceneCard(liveScenario),
        _buildActions(liveScenario),
        _buildSensorTrends(liveScenario, readings, isDemo: false),
        const SliverToBoxAdapter(child: SizedBox(height: AutoSpace.xxl + AutoSpace.xl)),
      ],
    );
  }

  Widget _buildDemoTab(List<SensorReading> readings) {
    final demoScenario = _demoScenarios[_demoScenarioIndex];
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildDemoNavigator(demoScenario),
        _buildSceneCard(demoScenario),
        _buildActions(demoScenario),
        _buildSensorTrends(demoScenario, readings, isDemo: true),
        const SliverToBoxAdapter(child: SizedBox(height: AutoSpace.xxl + AutoSpace.xl)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DEMO NAVIGATOR
  // ═══════════════════════════════════════════════════════════

  Widget _buildDemoNavigator(DemoScenarioData scenario) {
    final accent = AutoStatus.tagColor(scenario.tag);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AutoSpace.containerPadding, AutoSpace.md, AutoSpace.containerPadding, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: AutoSpace.md),
          decoration: BoxDecoration(
            color: AutoColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AutoRadius.xl),
            boxShadow: AutoShadow.card,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navButton(icon: Icons.chevron_left_rounded, onTap: _prevDemoScenario),
                  Column(
                    children: [
                      _StatusChip(label: 'SCENARIO', color: accent),
                      const SizedBox(height: AutoSpace.sm),
                      Text(
                        scenario.title,
                        style: AutoText.headlineMd.copyWith(fontSize: 18, height: 24 / 18, letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 2),
                      Text(scenario.subtitle, style: AutoText.labelMd),
                    ],
                  ),
                  _navButton(icon: Icons.chevron_right_rounded, onTap: _nextDemoScenario),
                ],
              ),
              const SizedBox(height: AutoSpace.md - 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_demoScenarios.length, (index) {
                  final isActive = index == _demoScenarioIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isActive ? accent : AutoColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AutoRadius.sm),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${_demoScenarioIndex + 1} / ${_demoScenarios.length}',
                style: AutoText.labelSm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AutoColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AutoRadius.md),
        ),
        child: Icon(icon, color: AutoColors.onSurface, size: 22),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SCENE CARD — 3:4 Video with Text Below
  // ═══════════════════════════════════════════════════════════

  Widget _buildSceneCard(dynamic scenario) {
    final tag = scenario is LiveScenarioData ? scenario.tag : (scenario as DemoScenarioData).tag;
    final subtitle = scenario is LiveScenarioData ? scenario.subtitle : (scenario as DemoScenarioData).subtitle;
    final videoAsset = scenario is LiveScenarioData ? scenario.videoAsset : (scenario as DemoScenarioData).videoAsset;
    final quote = scenario is LiveScenarioData ? scenario.quote : (scenario as DemoScenarioData).quote;
    final accent = AutoStatus.tagColor(tag);
    final (stableCount, alertCount) = _getStatusCounts(tag);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AutoSpace.containerPadding, AutoSpace.md, AutoSpace.containerPadding, 0),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AutoColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AutoRadius.xl),
            boxShadow: AutoShadow.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. The Video Section (Kept at 3/4 ratio)
              AspectRatio(
                aspectRatio: 3 / 4, 
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ScenarioVideoPlayer(key: ValueKey(videoAsset), videoAsset: videoAsset),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withValues(alpha:0.4), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: AutoSpace.md,
                      left: AutoSpace.md,
                      right: AutoSpace.md,
                      child: Row(
                        children: [
                          _GlassChip(label: tag, color: accent),
                          const Spacer(),
                          _GlassChip(label: '$stableCount', color: AutoColors.inversePrimary, icon: Icons.check_circle_rounded),
                          const SizedBox(width: 6),
                          _GlassChip(
                            label: '$alertCount',
                            color: alertCount > 0 ? accent : AutoColors.inversePrimary,
                            icon: alertCount > 0 ? Icons.error_rounded : Icons.warning_amber_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 2. The Text Section (Moved below the video)
              Container(
                padding: const EdgeInsets.fromLTRB(AutoSpace.md, AutoSpace.md, AutoSpace.md, AutoSpace.lg),
                color: AutoColors.surfaceContainerLowest,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subtitle,
                      style: AutoText.labelMd.copyWith(color: accent, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      quote,
                      style: AutoText.bodyMd.copyWith(fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ],
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
    final tag = scenario is LiveScenarioData ? scenario.tag : (scenario as DemoScenarioData).tag;
    final accent = AutoStatus.tagColor(tag);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AutoSpace.containerPadding, AutoSpace.lg, AutoSpace.containerPadding, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel(icon: Icons.tips_and_updates_outlined, label: 'Recommended Actions'),
            const SizedBox(height: AutoSpace.sm + 4),
            ...actions.map<Widget>((action) => _buildActionCard(action, accent)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(dynamic action, Color accent) {
    final icon = action is LiveAction ? action.icon : (action as DemoAction).icon;
    final label = action is LiveAction ? action.label : (action as DemoAction).label;
    final isCritical = action is LiveAction ? action.isCritical : (action as DemoAction).isCritical;
    final hasToggle = action is DemoAction ? action.hasToggle : false;
    final iconColor = isCritical ? AutoColors.error : AutoColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AutoSpace.sm + 2),
      padding: const EdgeInsets.all(AutoSpace.md),
      decoration: BoxDecoration(
        color: AutoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AutoRadius.lg),
        boxShadow: AutoShadow.card,
      ),
      child: Row(
        children: [
          if (isCritical)
            Container(
              width: 3,
              height: 32,
              margin: const EdgeInsets.only(right: AutoSpace.sm),
              decoration: BoxDecoration(color: AutoColors.error, borderRadius: BorderRadius.circular(AutoRadius.sm)),
            ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconColor.withValues(alpha:0.1), borderRadius: BorderRadius.circular(AutoRadius.md)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: AutoText.bodyMd.copyWith(fontWeight: FontWeight.w600, height: 1.3)),
          ),
          if (hasToggle) ...[
            const SizedBox(width: 12),
            _ActionToggle(accent: accent),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SENSOR TRENDS
  // ═══════════════════════════════════════════════════════════

  Widget _buildSensorTrends(dynamic scenario, List<SensorReading> readings, {required bool isDemo}) {
    final trends = isDemo
        ? (scenario as DemoScenarioData).sensorTrends
        : readings
            .map((r) => LiveTrend(
                  label: _shortLabel(r.label),
                  value: r.value,
                  unit: r.unit,
                  progress: _calculateProgress(r),
                  isCritical: r.status == SensorStatus.alert,
                ))
            .toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AutoSpace.containerPadding, AutoSpace.lg, AutoSpace.containerPadding, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel(icon: Icons.insights_outlined, label: 'Sensor Trends'),
            const SizedBox(height: AutoSpace.sm + 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AutoSpace.md, vertical: AutoSpace.sm),
              decoration: BoxDecoration(
                color: AutoColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AutoRadius.xl),
                boxShadow: AutoShadow.card,
              ),
              child: Column(children: trends.map<Widget>((t) => _buildTrendRow(t)).toList()),
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
    final color = isCritical ? AutoColors.error : AutoColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AutoSpace.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha:0.1), shape: BoxShape.circle),
            child: Icon(_trendIcon(label), color: color, size: 16),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(label, style: AutoText.labelSm.copyWith(letterSpacing: 0.4)),
          ),
          Expanded(child: _GradientProgressBar(progress: progress, color: color)),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              '${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)} $unit',
              textAlign: TextAlign.right,
              style: AutoText.labelMd.copyWith(
                color: isCritical ? AutoColors.error : AutoColors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _trendIcon(String label) {
    switch (label) {
      case 'TEMP':
        return Icons.thermostat_outlined;
      case 'HUMID':
        return Icons.water_drop_outlined;
      case 'LIGHT':
        return Icons.wb_sunny_outlined;
      case 'SOIL':
        return Icons.grass_outlined;
      case 'pH':
        return Icons.science_outlined;
      case 'EC':
        return Icons.bolt_outlined;
      default:
        return Icons.sensors_outlined;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// SMALL SHARED WIDGETS
// ═══════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AutoColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: AutoText.labelSm.copyWith(letterSpacing: 1.1),
        ),
      ],
    );
  }
}

/// Small pill chip with a light tint of [color] — for use over light
/// (card) surfaces, per the design system's "Status Chips" spec.
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatusChip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(AutoRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Text(
            label,
            style: AutoText.labelSm.copyWith(color: color, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}

/// Semi-transparent chip — for use directly over the video/hero image.
class _GlassChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _GlassChip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.4),
        borderRadius: BorderRadius.circular(AutoRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha:0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: Colors.white), const SizedBox(width: 4)],
          Text(
            label,
            style: AutoText.labelSm.copyWith(color: Colors.white, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

/// Rounded track with a soft two-stop gradient fill, echoing the design
/// system's chart guidance ("fill under the line with a soft gradient").
class _GradientProgressBar extends StatelessWidget {
  final double progress;
  final Color color;

  const _GradientProgressBar({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AutoRadius.sm),
      child: Container(
        height: 8,
        color: AutoColors.surfaceContainerHigh,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withValues(alpha:0.55), color]),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ACTION TOGGLE — OFF / AUTO / ON segmented pill
// ═══════════════════════════════════════════════════════════

class _ActionToggle extends StatefulWidget {
  final Color accent;
  const _ActionToggle({required this.accent});

  @override
  State<_ActionToggle> createState() => _ActionToggleState();
}

class _ActionToggleState extends State<_ActionToggle> {
  int _mode = 1; // 0 = OFF, 1 = AUTO, 2 = ON

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AutoColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AutoRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg('OFF', 0),
          _seg('AUTO', 1, accent: true),
          _seg('ON', 2),
        ],
      ),
    );
  }

  Widget _seg(String label, int value, {bool accent = false}) {
    final selected = _mode == value;
    return GestureDetector(
      onTap: () => setState(() => _mode = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? (accent ? widget.accent : AutoColors.surfaceContainerLowest) : Colors.transparent,
          borderRadius: BorderRadius.circular(AutoRadius.full),
          boxShadow: selected ? AutoShadow.card : null,
        ),
        child: Text(
          label,
          style: AutoText.labelSm.copyWith(
            color: selected ? (accent ? Colors.white : AutoColors.onSurface) : AutoColors.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════

class LiveScenarioData {
  final String title;
  final String tag;
  final String subtitle;
  final String videoAsset;
  final String quote;
  final List<LiveAction> actions;
  final List<LiveTrend> sensorTrends;

  LiveScenarioData({
    required this.title,
    required this.tag,
    required this.subtitle,
    required this.videoAsset,
    required this.quote,
    required this.actions,
    required this.sensorTrends,
  });
}

class LiveAction {
  final IconData icon;
  final String label;
  final bool isCritical;
  LiveAction({required this.icon, required this.label, this.isCritical = false});
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

class DemoScenarioData {
  final String title;
  final String tag;
  final String subtitle;
  final String videoAsset;
  final String quote;
  final List<DemoAction> actions;
  final List<DemoTrend> sensorTrends;

  DemoScenarioData({
    required this.title,
    required this.tag,
    required this.subtitle,
    required this.videoAsset,
    required this.quote,
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