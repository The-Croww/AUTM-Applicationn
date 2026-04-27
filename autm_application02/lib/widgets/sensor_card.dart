import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';

class SensorCard extends StatelessWidget {
  final SensorReading reading;
  final VoidCallback? onTap;
  const SensorCard({super.key, required this.reading, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(reading.status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bg1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SensorIcon(iconName: reading.icon, color: color),
                _StatusBadge(status: reading.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmt(reading.value, reading.unit),
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -1)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(reading.unit,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(reading.label,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: reading.percentage,
                backgroundColor: AppTheme.bg3,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${reading.min}${reading.unit}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                Text('${reading.max}${reading.unit}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v, String unit) {
    if (unit == 'lux') return v.round().toString();
    if (unit == 'pH' || unit == 'mS/cm') return v.toStringAsFixed(2);
    return v.toStringAsFixed(1);
  }
}

class _SensorIcon extends StatelessWidget {
  final String iconName;
  final Color color;
  const _SensorIcon({required this.iconName, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_icon(iconName), color: color, size: 18),
    );
  }

  IconData _icon(String name) {
    switch (name) {
      case 'thermostat': return Icons.thermostat;
      case 'water_drop': return Icons.water_drop;
      case 'wb_sunny':   return Icons.wb_sunny;
      case 'grass':      return Icons.grass;
      case 'science':    return Icons.science;
      case 'bolt':       return Icons.bolt;
      default:           return Icons.sensors;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final SensorStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(statusLabel(status),
          style: TextStyle(
              color: color, fontSize: 10,
              fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }
}