import 'package:flutter/material.dart';
import 'package:automato/domain/models/sensor_data.dart';
import 'package:automato/presentation/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// FLOATING CARD — PREMIUM MODERN EXPERIENCE
// ─────────────────────────────────────────────────────────────
class FloatingCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final double borderRadius;

  const FloatingCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor = Colors.white, // Pure white contrast on bg0 warm canvas
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03), // Ambient soft shadow
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02), // Layered depth
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SENSOR CARD — FLOATING & HIGH-INFORMATION
// ─────────────────────────────────────────────────────────────
class SensorCard extends StatelessWidget {
  final SensorReading reading;
  final VoidCallback onTap;

  const SensorCard({
    super.key,
    required this.reading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = cardColorsFor(reading.status);
    final analysis = getAnalysisText(reading);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: FloatingCard(
        onTap: onTap,
        backgroundColor: colors.background,
        borderRadius: 16.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row: Category Icon, Title & Status Badge ─────────────────────
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colors.badgeBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            iconForSensor(reading.icon),
                            color: colors.badgeText,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          reading.label.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.badgeBg,
                      borderRadius: BorderRadius.circular(20), // Pill status badge
                    ),
                    child: Text(
                      statusLabel(reading.status),
                      style: TextStyle(
                        color: colors.badgeText,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Main Content Block: Telemetry Values & Target ──────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatValue(reading.value),
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          height: 0.95,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reading.unit,
                        style: const TextStyle(
                          color: AppTheme.inkMid,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'OPTIMAL TARGET',
                        style: TextStyle(
                          color: AppTheme.inkFaint,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${reading.min.toStringAsFixed(0)} - ${reading.max.toStringAsFixed(0)} ${reading.unit}',
                        style: const TextStyle(
                          color: AppTheme.inkMid,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Smart Analysis Telemetry Output (Premium inline banner) ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.analysisBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      reading.status == SensorStatus.normal
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      color: colors.badgeText,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        analysis,
                        style: TextStyle(
                          color: colors.badgeText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      timeAgo(reading.timestamp),
                      style: const TextStyle(
                        color: AppTheme.inkFaint,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Threshold Slider Track (Pill styled slider) ──
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.track,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: reading.percentage.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getAnalysisText(SensorReading r) {
    if (r.value < r.min) {
      final diff = (r.min - r.value).toStringAsFixed(1);
      return 'Deficit of $diff${r.unit}';
    } else if (r.value > r.max) {
      final diff = (r.value - r.max).toStringAsFixed(1);
      return 'Surplus of $diff${r.unit}';
    } else {
      return 'Stable & Optimal';
    }
  }

  CardColors cardColorsFor(SensorStatus status) {
    switch (status) {
      case SensorStatus.normal:
        return const CardColors(
          background: Colors.white,
          accent: AppTheme.statusNormal,
          track: Color(0xFFE4ECD9),
          badgeBg: Color(0xFFF1EDE7),
          badgeText: AppTheme.statusNormal,
          analysisBg: Color(0xFFF9F5F0),
        );
      case SensorStatus.warning:
        return const CardColors(
          background: Color(0xFFFCF7F2),
          accent: AppTheme.statusWarning,
          track: Color(0xFFE5CCB3),
          badgeBg: Color(0xFFFFF2E6),
          badgeText: AppTheme.statusWarning,
          analysisBg: Color(0xFFFFF7EF),
        );
      case SensorStatus.alert:
        return const CardColors(
          background: Color(0xFFFDF5F5),
          accent: AppTheme.statusAlert,
          track: Color(0xFFE5B3B3),
          badgeBg: Color(0xFFFFECEC),
          badgeText: AppTheme.statusAlert,
          analysisBg: Color(0xFFFFF2F2),
        );
    }
  }

  String statusLabel(SensorStatus status) {
    switch (status) {
      case SensorStatus.normal:
        return 'NORMAL';
      case SensorStatus.warning:
        return 'WARNING';
      case SensorStatus.alert:
        return 'CRITICAL';
    }
  }

  String formatValue(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  IconData iconForSensor(String iconName) {
    switch (iconName) {
      case 'thermostat':
      case 'temperature':
        return Icons.thermostat_rounded;
      case 'water_drop':
      case 'humidity':
        return Icons.water_drop_rounded;
      case 'wb_sunny':
      case 'light':
        return Icons.wb_sunny_rounded;
      case 'co2':
        return Icons.cloud_rounded;
      case 'speed':
      case 'fan':
        return Icons.speed_rounded;
      case 'soil':
        return Icons.grass_rounded;
      default:
        return Icons.sensors_rounded;
    }
  }

  String timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class CardColors {
  final Color background;
  final Color accent;
  final Color track;
  final Color badgeBg;
  final Color badgeText;
  final Color analysisBg;

  const CardColors({
    required this.background,
    required this.accent,
    required this.track,
    required this.badgeBg,
    required this.badgeText,
    required this.analysisBg,
  });
}