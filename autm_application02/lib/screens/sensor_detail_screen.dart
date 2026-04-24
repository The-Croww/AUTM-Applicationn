import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class SensorDetailScreen extends StatelessWidget {
  final String sensorId;
  const SensorDetailScreen({super.key, required this.sensorId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final reading = state.readings.firstWhere((r) => r.id == sensorId);
        final history = state.historyFor(sensorId);
        final color = statusColor(reading.status);

        return Scaffold(
          backgroundColor: AppTheme.bg0,
          appBar: AppBar(
            title: Text(reading.label),
            leading: const BackButton(),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _BigValueCard(reading: reading, color: color),
              const SizedBox(height: 16),
              _ChartCard(history: history, color: color, reading: reading),
              const SizedBox(height: 16),
              _ThresholdCard(reading: reading),
            ],
          ),
        );
      },
    );
  }
}

class _BigValueCard extends StatelessWidget {
  final SensorReading reading;
  final Color color;
  const _BigValueCard({required this.reading, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current reading',
                  style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _fmt(reading.value, reading.unit),
                      style: TextStyle(
                        color: color,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -2,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 6),
                      child: Text(reading.unit,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 16)),
                    ),
                  ],
                ),
                Text(
                  statusLabel(reading.status),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(_iconData(reading.icon), color: color, size: 30),
          ),
        ],
      ),
    );
  }

  String _fmt(double v, String unit) {
    if (unit == 'lux') return v.round().toString();
    if (unit == 'pH' || unit == 'mS/cm') return v.toStringAsFixed(2);
    return v.toStringAsFixed(1);
  }

  IconData _iconData(String name) {
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

class _ChartCard extends StatelessWidget {
  final SensorHistory history;
  final Color color;
  final SensorReading reading;
  const _ChartCard({required this.history, required this.color, required this.reading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Last 4 hours',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _LinePainter(
                points: history.points,
                color: color,
                warningLow: reading.warningLow,
                warningHigh: reading.warningHigh,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_timeLabel(history.points.isNotEmpty ? history.points.first.time : DateTime.now()),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              Text('Now',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _LinePainter extends CustomPainter {
  final List<SensorDataPoint> points;
  final Color color;
  final double warningLow;
  final double warningHigh;

  _LinePainter({
    required this.points,
    required this.color,
    required this.warningLow,
    required this.warningHigh,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final values = points.map((p) => p.value).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1.0 : maxV - minV;
    final pad = range * 0.15;

    double nx(int i) => i / (points.length - 1) * size.width;
    double ny(double v) => size.height - ((v - minV + pad) / (range + pad * 2)) * size.height;

    // Safe zone band
    final bandPaint = Paint()
      ..color = AppTheme.statusNormal.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    final bandTop = ny(warningHigh.clamp(minV - pad, maxV + pad));
    final bandBot = ny(warningLow.clamp(minV - pad, maxV + pad));
    canvas.drawRect(Rect.fromLTRB(0, bandTop, size.width, bandBot), bandPaint);

    // Gradient fill under line
    final fillPath = Path();
    fillPath.moveTo(nx(0), size.height);
    for (int i = 0; i < points.length; i++) {
      fillPath.lineTo(nx(i), ny(points[i].value));
    }
    fillPath.lineTo(nx(points.length - 1), size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePath = Path();
    linePath.moveTo(nx(0), ny(points[0].value));
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(nx(i), ny(points[i].value));
    }
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Last point dot
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(
      Offset(nx(points.length - 1), ny(points.last.value)),
      4,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points || old.color != color;
}

class _ThresholdCard extends StatelessWidget {
  final SensorReading reading;
  const _ThresholdCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thresholds',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _ThresholdRow(
              label: 'Warning low',
              value: '${reading.warningLow} ${reading.unit}',
              color: AppTheme.statusWarning),
          _ThresholdRow(
              label: 'Warning high',
              value: '${reading.warningHigh} ${reading.unit}',
              color: AppTheme.statusWarning),
          _ThresholdRow(
              label: 'Sensor range',
              value: '${reading.min} – ${reading.max} ${reading.unit}',
              color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

class _ThresholdRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ThresholdRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}