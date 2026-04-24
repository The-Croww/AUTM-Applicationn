import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedSensor = 'temperature';

  static const _sensorOptions = [
    ('temperature', 'Temp'),
    ('humidity', 'Humidity'),
    ('light', 'Light'),
    ('moisture', 'Moisture'),
    ('ph', 'pH'),
    ('ec', 'EC'),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final reading = state.readings.firstWhere((r) => r.id == _selectedSensor);
        final history = state.historyFor(_selectedSensor);
        final color = statusColor(reading.status);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSensorPicker(),
            const SizedBox(height: 20),
            _buildStatsRow(reading, history),
            const SizedBox(height: 16),
            _buildChartCard(reading, history, color),
            const SizedBox(height: 16),
            _buildAllSensorsTable(state),
          ],
        );
      },
    );
  }

  Widget _buildSensorPicker() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _sensorOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (id, label) = _sensorOptions[i];
          final selected = id == _selectedSensor;
          return GestureDetector(
            onTap: () => setState(() => _selectedSensor = id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppTheme.bg3 : AppTheme.bg1,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppTheme.textSecondary.withOpacity(0.4) : AppTheme.divider,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(SensorReading reading, SensorHistory history) {
    final values = history.points.map((p) => p.value).toList();
    final avg = values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
    final min = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    final max = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Current', value: _fmt(reading.value, reading.unit))),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Average', value: _fmt(avg, reading.unit))),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Min', value: _fmt(min, reading.unit))),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Max', value: _fmt(max, reading.unit))),
      ],
    );
  }

  Widget _buildChartCard(SensorReading reading, SensorHistory history, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(reading.label,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              const Text('6h trend',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _AnalyticsChartPainter(
                points: history.points,
                color: color,
                warningLow: reading.warningLow,
                warningHigh: reading.warningHigh,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                history.points.isNotEmpty ? _timeFmt(history.points.first.time) : '',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              const Text('Now', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllSensorsTable(AppState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text('All sensors',
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const Divider(height: 1),
          ...state.readings.map((r) => _SensorTableRow(reading: r)),
        ],
      ),
    );
  }

  String _fmt(double v, String unit) {
    if (unit == 'lux') return '${v.round()}';
    if (unit == 'pH' || unit == 'mS/cm') return v.toStringAsFixed(2);
    return '${v.toStringAsFixed(1)} $unit';
  }

  String _timeFmt(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SensorTableRow extends StatelessWidget {
  final SensorReading reading;
  const _SensorTableRow({required this.reading});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(reading.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          Expanded(
            child: Text(reading.label,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          ),
          Text(_fmt(reading.value, reading.unit),
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _fmt(double v, String unit) {
    if (unit == 'lux') return '${v.round()} $unit';
    if (unit == 'pH' || unit == 'mS/cm') return '${v.toStringAsFixed(2)} $unit';
    return '${v.toStringAsFixed(1)} $unit';
  }
}

class _AnalyticsChartPainter extends CustomPainter {
  final List<SensorDataPoint> points;
  final Color color;
  final double warningLow;
  final double warningHigh;

  _AnalyticsChartPainter({
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
    final pad = range * 0.2;

    double nx(int i) => i / (points.length - 1) * size.width;
    double ny(double v) =>
        size.height - ((v - minV + pad) / (range + pad * 2)) * size.height;

    final safeZonePaint = Paint()
      ..color = AppTheme.statusNormal.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(0, ny(warningHigh.clamp(minV - pad, maxV + pad)),
          size.width, ny(warningLow.clamp(minV - pad, maxV + pad))),
      safeZonePaint,
    );

    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    for (int i = 1; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    final fillPath = Path()..moveTo(nx(0), size.height);
    for (int i = 0; i < points.length; i++) {
      fillPath.lineTo(nx(i), ny(points[i].value));
    }
    fillPath.lineTo(nx(points.length - 1), size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final linePath = Path()..moveTo(nx(0), ny(points[0].value));
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(nx(i), ny(points[i].value));
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_AnalyticsChartPainter old) => old.points != points;
}