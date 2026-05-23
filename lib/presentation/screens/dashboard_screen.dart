import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/sensor_data.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sensor_card.dart';
import 'sensor_detail_screen.dart';
import 'alerts_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return CustomScrollView(
      slivers: [
        _buildStatusRow(state),
        _buildGreenhouseHealthCard(context, state),
        if (state.alertCount > 0) _buildAlertBanner(context, state),
        _buildSensorGrid(context, state),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildStatusRow(AppState state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.isConnected ? AppTheme.textPrimary : AppTheme.statusAlert,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              state.connectionLabel,
              style: TextStyle(
                color: state.isConnected ? AppTheme.textSecondary : AppTheme.statusAlert,
                fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Text(_fmt(state.lastUpdated),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner(BuildContext context, AppState state) {
    final alertSensors = state.readings
        .where((r) => r.status == SensorStatus.alert)
        .toList();
    
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AlertsScreen())),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: AppTheme.statusAlert.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.statusAlert.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.statusAlert, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${alertSensors.length} sensor${alertSensors.length > 1 ? 's' : ''} out of range: '
                  '${alertSensors.map((a) => a.label).join(', ')}',
                  style: const TextStyle(
                      color: AppTheme.statusAlert, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.statusAlert, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorGrid(BuildContext context, AppState state) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12,
          mainAxisSpacing: 12, childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final r = state.readings[i];
            return SensorCard(
              reading: r,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SensorDetailScreen(sensorId: r.id))),
            );
          },
          childCount: state.readings.length,
        ),
      ),
    );
  }

  String _fmt(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return 'Updated $h:$m:$s';
  }

  Widget _buildGreenhouseHealthCard(BuildContext context, AppState state) {
  final total = state.readings.length;
  if (total == 0) return const SliverToBoxAdapter(child: SizedBox.shrink());

  final alertCount   = state.readings.where((r) => r.status == SensorStatus.alert).length;
  final warningCount = state.readings.where((r) => r.status == SensorStatus.warning).length;
  final normalCount  = state.readings.where((r) => r.status == SensorStatus.normal).length;

  // Weighted score: normal=1.0, warning=0.5, alert=0.0
  final score   = ((normalCount * 1.0 + warningCount * 0.5) / total).clamp(0.0, 1.0);
  final percent = (score * 100).round();

  final statusColor = score >= 0.8
      ? AppTheme.statusNormal
      : score >= 0.5
          ? AppTheme.statusWarning
          : AppTheme.statusAlert;

  final statusSurfaceColor = score >= 0.8
      ? AppTheme.normalSurface
      : score >= 0.5
          ? AppTheme.warningSurface
          : AppTheme.alertSurface;

  final statusText = score >= 0.8
      ? 'NORMAL'
      : score >= 0.5
          ? 'WARNING'
          : 'CRITICAL';

  final statusIcon = score >= 0.8
      ? Icons.eco_rounded
      : score >= 0.5
          ? Icons.thermostat_rounded
          : Icons.warning_amber_rounded;

  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.bg1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.local_florist_rounded,
                    color: AppTheme.inkFaint, size: 13),
                const SizedBox(width: 6),
                const Text(
                  'GREENHOUSE HEALTH',
                  style: TextStyle(
                    color: AppTheme.inkFaint,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusSurfaceColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 5),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Score + breakdown ─────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$percent',
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    '%',
                    style: TextStyle(
                      color: AppTheme.inkMid,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                // Dot legend
                Row(
                  children: [
                    _buildDot(normalCount, AppTheme.statusNormal, 'OK'),
                    if (warningCount > 0) ...[
                      const SizedBox(width: 6),
                      _buildDot(warningCount, AppTheme.statusWarning, 'WARN'),
                    ],
                    if (alertCount > 0) ...[
                      const SizedBox(width: 6),
                      _buildDot(alertCount, AppTheme.statusAlert, 'ALERT'),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Segmented bar ─────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 5,
                child: Row(
                  children: [
                    if (normalCount > 0)
                      Expanded(
                        flex: normalCount,
                        child: Container(color: AppTheme.statusNormal),
                      ),
                    if (warningCount > 0)
                      Expanded(
                        flex: warningCount,
                        child: Container(color: AppTheme.statusWarning),
                      ),
                    if (alertCount > 0)
                      Expanded(
                        flex: alertCount,
                        child: Container(color: AppTheme.statusAlert),
                      ),
                    // Fill remaining if all normal
                    if (normalCount == total)
                      Expanded(
                        flex: 1,
                        child: Container(color: AppTheme.statusNormal),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Footer ────────────────────────────────────────
            Text(
              '$normalCount of $total sensors normal',
              style: const TextStyle(
                color: AppTheme.inkFaint,
                fontSize: 12,
              ),
            ),

          ],
        ),
      ),
    ),
  );
}

Widget _buildDot(int count, Color color, String label) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7, height: 7,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
      const SizedBox(width: 4),
      Text(
        '$count $label',
        style: const TextStyle(color: AppTheme.inkFaint, fontSize: 11),
      ),
    ],
  );
}

}