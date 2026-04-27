import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final active   = state.allAlerts.where((a) => !a.isResolved).toList();
        final resolved = state.allAlerts.where((a) => a.isResolved).toList();

        return Scaffold(
          backgroundColor: AppTheme.bg0,
          appBar: AppBar(title: const Text('Alerts')),
          body: state.allAlerts.isEmpty
              ? _emptyState()
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (active.isNotEmpty) ...[
                      _sectionLabel('Active — ${active.length}'),
                      const SizedBox(height: 10),
                      ...active.map((a) => _AlertTile(alert: a, active: true)),
                      const SizedBox(height: 24),
                    ],
                    if (resolved.isNotEmpty) ...[
                      _sectionLabel('Resolved — ${resolved.length}'),
                      const SizedBox(height: 10),
                      ...resolved.map((a) => _AlertTile(alert: a, active: false)),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600));

  Widget _emptyState() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.statusNormal, size: 48),
            SizedBox(height: 12),
            Text('No alerts', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('All sensors are within normal range.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
}

class _AlertTile extends StatelessWidget {
  final AlertRecord alert;
  final bool active;
  const _AlertTile({required this.alert, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.statusAlert : AppTheme.textMuted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active
            ? AppTheme.statusAlert.withOpacity(0.25)
            : AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              active ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.sensorLabel,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${alert.value.toStringAsFixed(2)} ${alert.unit}  •  ${_timeAgo(alert.createdAt)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                if (alert.isResolved && alert.resolvedAt != null)
                  Text('Resolved ${_timeAgo(alert.resolvedAt!)}',
                      style: const TextStyle(color: AppTheme.statusNormal, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(active ? 'ACTIVE' : 'RESOLVED',
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60)  return '${d.inSeconds}s ago';
    if (d.inMinutes < 60)  return '${d.inMinutes}m ago';
    if (d.inHours < 24)    return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}