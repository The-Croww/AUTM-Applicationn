import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/sensor_data.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class SensorDetailScreen extends StatefulWidget {
  final String sensorId;
  const SensorDetailScreen({super.key, required this.sensorId});

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  SensorHistory? _history;
  bool _loading = true;
  String? _error;
  int? _tooltipIndex;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final state = context.read<AppState>();
      final history = await state.fetchHistory(widget.sensorId);
      setState(() {
        _history = history;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load history';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final reading = state.readings.firstWhere((r) => r.id == widget.sensorId);
        final color = statusColor(reading.status);
        final history = _history ?? state.historyFor(widget.sensorId);

        return Scaffold(
          backgroundColor: AppTheme.bg0,
          appBar: AppBar(
            title: Text(reading.label),
            leading: const BackButton(),
          ),
          body: RefreshIndicator(
            onRefresh: _loadHistory,
            color: AppTheme.olive,
            backgroundColor: AppTheme.bg1,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _BigValueCard(reading: reading, color: color),
                const SizedBox(height: 16),
                if (_error != null)
                  _buildErrorCard()
                else ...[
                  if (_loading)
                    const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _buildEnhancedChartCard(reading, history.points, color),
                    const SizedBox(height: 16),
                    _buildTimeInRangeCard(reading, history.points),
                    const SizedBox(height: 16),
                    _buildBreachEventsCard(reading, history.points),
                  ],
                  const SizedBox(height: 16),
                  _ThresholdCard(reading: reading),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.alertSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.statusAlert, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: AppTheme.statusAlert, fontSize: 13),
            ),
          ),
          TextButton(onPressed: _loadHistory, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEnhancedChartCard(
      SensorReading reading, List<SensorDataPoint> points, Color color) {
    if (points.length < 2) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.bg1,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          height: 140,
          child: Center(child: Text('Not enough data')),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Last 6 hours',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                _buildYAxisLabels(points),
                const SizedBox(width: 4),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          setState(() {
                            _tooltipIndex = _findClosestIndex(
                              details.localPosition.dx,
                              points,
                              constraints.maxWidth,
                            );
                          });
                        },
                        onHorizontalDragStart: (details) {
                          setState(() {
                            _tooltipIndex = _findClosestIndex(
                              details.localPosition.dx,
                              points,
                              constraints.maxWidth,
                            );
                          });
                        },
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _tooltipIndex = _findClosestIndex(
                              details.localPosition.dx,
                              points,
                              constraints.maxWidth,
                            );
                          });
                        },
                        child: Stack(
                          children: [
                            CustomPaint(
                              painter: _DetailChartPainter(
                                points: points,
                                color: color,
                                warningLow: reading.warningLow,
                                warningHigh: reading.warningHigh,
                                tooltipIndex: _tooltipIndex,
                              ),
                              size: Size.infinite,
                            ),
                            if (_tooltipIndex != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bg0.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.divider),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${points[_tooltipIndex!].value.toStringAsFixed(1)}${reading.unit}',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        _timeFmt(points[_tooltipIndex!].time),
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYAxisLabels(List<SensorDataPoint> points) {
    final values = points.map((p) => p.value).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = maxV - minV;
    final pad = range * 0.2;
    final top = maxV + pad;
    final bottom = minV - pad;
    final mid = (top + bottom) / 2;

    return SizedBox(
      width: 25,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_compactFmt(top),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          Text(_compactFmt(mid),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          Text(_compactFmt(bottom),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTimeInRangeCard(
      SensorReading reading, List<SensorDataPoint> points) {
    if (points.isEmpty) return const SizedBox.shrink();

    final total = points.length;
    final normalCount = points.where((p) =>
        p.value >= reading.warningLow && p.value <= reading.warningHigh).length;
    final lowCount = points.where((p) => p.value < reading.warningLow).length;
    final highCount = points.where((p) => p.value > reading.warningHigh).length;

    final normalPct = (normalCount / total * 100).round();
    final lowPct = (lowCount / total * 100).round();
    final highPct = (highCount / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Time in Range',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                if (normalPct > 0)
                  Expanded(
                      flex: normalPct,
                      child: Container(height: 8, color: AppTheme.statusNormal)),
                if (lowPct > 0)
                  Expanded(
                      flex: lowPct,
                      child: Container(height: 8, color: AppTheme.statusWarning)),
                if (highPct > 0)
                  Expanded(
                      flex: highPct,
                      child: Container(height: 8, color: AppTheme.statusAlert)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _RangeLegend(color: AppTheme.statusNormal, label: 'Normal', value: '$normalPct%'),
              const SizedBox(width: 12),
              _RangeLegend(color: AppTheme.statusWarning, label: 'Low', value: '$lowPct%'),
              const SizedBox(width: 12),
              _RangeLegend(color: AppTheme.statusAlert, label: 'High', value: '$highPct%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreachEventsCard(
      SensorReading reading, List<SensorDataPoint> points) {
    if (points.isEmpty) return const SizedBox.shrink();

    final breaches = <_BreachEvent>[];
    _BreachEvent? current;

    for (final point in points) {
      final isLow = point.value < reading.warningLow;
      final isHigh = point.value > reading.warningHigh;

      if (!isLow && !isHigh) {
        if (current != null) {
          current.endTime = point.time;
          breaches.add(current);
          current = null;
        }
        continue;
      }

      if (current == null || current.isHigh != isHigh) {
        if (current != null) {
          current.endTime = point.time;
          breaches.add(current);
        }
        current = _BreachEvent(
          startTime: point.time,
          isHigh: isHigh,
          peakValue: point.value,
          limit: isHigh ? reading.warningHigh : reading.warningLow,
        );
      } else {
        if (isHigh && point.value > current.peakValue) {
          current.peakValue = point.value;
        } else if (!isHigh && point.value < current.peakValue) {
          current.peakValue = point.value;
        }
      }
    }

    if (current != null) {
      current.endTime = current.startTime;
      breaches.add(current);
    }

    if (breaches.isEmpty) return const SizedBox.shrink();

    final recent = breaches.length > 5 ? breaches.sublist(breaches.length - 5) : breaches;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Threshold Events',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.statusAlert.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${breaches.length} total',
                    style: TextStyle(
                        color: AppTheme.statusAlert,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recent.reversed.map((b) => _BreachEventRow(breach: b, unit: reading.unit)),
        ],
      ),
    );
  }

  String _compactFmt(double v) {
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  String _timeFmt(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  int _findClosestIndex(
      double dx, List<SensorDataPoint> points, double chartWidth) {
    if (points.length < 2) return 0;
    final segmentWidth = chartWidth / (points.length - 1);
    return (dx / segmentWidth).round().clamp(0, points.length - 1);
  }
}

// ── Big value card ───────────────────────────────────────────
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
                const Text('Current reading',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
      case 'wb_sunny': return Icons.wb_sunny;
      case 'grass': return Icons.grass;
      case 'science': return Icons.science;
      case 'bolt': return Icons.bolt;
      default: return Icons.sensors;
    }
  }
}

// ── Threshold card ───────────────────────────────────────────
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
  const _ThresholdRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Supporting classes ───────────────────────────────────────
class _RangeLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _RangeLegend({
    required this.color,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _BreachEvent {
  DateTime startTime;
  DateTime? endTime;
  final bool isHigh;
  double peakValue;
  final double limit;
  _BreachEvent({
    required this.startTime,
    this.endTime,
    required this.isHigh,
    required this.peakValue,
    required this.limit,
  });
}

class _BreachEventRow extends StatelessWidget {
  final _BreachEvent breach;
  final String unit;
  const _BreachEventRow({required this.breach, required this.unit});
  @override
  Widget build(BuildContext context) {
    final color = breach.isHigh ? AppTheme.statusAlert : AppTheme.statusWarning;
    final icon = breach.isHigh ? Icons.arrow_upward : Icons.arrow_downward;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  breach.isHigh ? 'High threshold exceeded' : 'Low threshold exceeded',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  '${_fmtTime(breach.startTime)} \u2022 Peak: ${breach.peakValue.toStringAsFixed(1)}$unit',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  String _fmtTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Chart Painter (enhanced) ─────────────────────────────────
class _DetailChartPainter extends CustomPainter {
  final List<SensorDataPoint> points;
  final Color color;
  final double warningLow;
  final double warningHigh;
  final int? tooltipIndex;

  _DetailChartPainter({
    required this.points,
    required this.color,
    required this.warningLow,
    required this.warningHigh,
    this.tooltipIndex,
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

    // Safe zone
    canvas.drawRect(
      Rect.fromLTRB(
        0,
        ny(warningHigh.clamp(minV - pad, maxV + pad)),
        size.width,
        ny(warningLow.clamp(minV - pad, maxV + pad)),
      ),
      Paint()
        ..color = AppTheme.statusNormal.withOpacity(0.06)
        ..style = PaintingStyle.fill,
    );

    // Threshold lines
    final thresholdPaint = Paint()
      ..color = AppTheme.statusWarning.withOpacity(0.3)
      ..strokeWidth = 1;
    if (warningLow >= minV - pad && warningLow <= maxV + pad) {
      canvas.drawLine(Offset(0, ny(warningLow)), Offset(size.width, ny(warningLow)), thresholdPaint);
    }
    if (warningHigh >= minV - pad && warningHigh <= maxV + pad) {
      canvas.drawLine(Offset(0, ny(warningHigh)), Offset(size.width, ny(warningHigh)), thresholdPaint);
    }

    // Gradient fill
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
          colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
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

    // Last point dot
    canvas.drawCircle(
      Offset(nx(points.length - 1), ny(points.last.value)),
      4,
      Paint()..color = color,
    );

    // Tooltip highlight
    if (tooltipIndex != null) {
      final index = tooltipIndex!;
      final x = nx(index);
      final y = ny(points[index].value);

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = color.withOpacity(0.3)
          ..strokeWidth = 1,
      );

      canvas.drawCircle(Offset(x, y), 6, Paint()..color = color);
      canvas.drawCircle(Offset(x, y), 10, Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_DetailChartPainter old) =>
      old.points != points ||
      old.color != color ||
      old.tooltipIndex != tooltipIndex;
}