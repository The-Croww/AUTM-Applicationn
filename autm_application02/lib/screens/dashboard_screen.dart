import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sensor_card.dart';
import 'sensor_detail_screen.dart';
import '../models/sensor_data.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return CustomScrollView(
          slivers: [
            _buildHeader(context, state),
            _buildAlertBanner(context, state),
            _buildSensorGrid(context, state),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppState state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.isConnected
                    ? AppTheme.textPrimary
                    : AppTheme.statusAlert,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              state.isConnected ? 'LIVE' : 'OFFLINE',
              style: TextStyle(
                color: state.isConnected
                    ? AppTheme.textSecondary
                    : AppTheme.statusAlert,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Text(
              _formatTime(state.lastUpdated),
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner(BuildContext context, AppState state) {
    final alerts = state.readings.where((r) => r.status == SensorStatus.alert).toList();
    if (alerts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                '${alerts.length} sensor${alerts.length > 1 ? 's' : ''} out of range: '
                '${alerts.map((a) => a.label).join(', ')}',
                style: const TextStyle(
                  color: AppTheme.statusAlert,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGrid(BuildContext context, AppState state) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final reading = state.readings[index];
            return SensorCard(
              reading: reading,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SensorDetailScreen(sensorId: reading.id),
                ),
              ),
            );
          },
          childCount: state.readings.length,
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return 'Updated $h:$m:$s';
  }
}