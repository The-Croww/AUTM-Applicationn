//dashboard_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:automato/domain/models/sensor_data.dart';
import 'package:automato/presentation/providers/app_state.dart';
import 'package:automato/presentation/theme/app_theme.dart';
import 'package:automato/presentation/widgets/sensor_card.dart';
import 'package:automato/presentation/screens/sensor_detail/sensor_detail_screen.dart';
import 'package:automato/presentation/screens/alerts/alerts_screen.dart';
import 'package:automato/presentation/screens/analytics/analytics_screen.dart';

// ─────────────────────────────────────────────────────────────
// DASHBOARD — Original Live Data Only (No Scenario/MP4)
// ─────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _onRefresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppTheme.bg0,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.olive,
          backgroundColor: AppTheme.bg1,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildGreenhouseHealthStatus(state),
              if (state.alertCount > 0)
                _buildAlertBanner(context, state),
              _buildSensorsSectionHeader(),
              _buildDeviceStatusRow(state),
              _buildSensorCards(context, state),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreenhouseHealthStatus(AppState state) {
    final total = state.readings.length;
    if (total == 0) {
      return const SliverToBoxAdapter(
        child: _HealthGridShimmer(),
      );
    }

    final alertCount = state.readings.where((r) => r.status == SensorStatus.alert).length;
    final warningCount = state.readings.where((r) => r.status == SensorStatus.warning).length;
    final normalCount = state.readings.where((r) => r.status == SensorStatus.normal).length;

    final score = ((normalCount * 1.0 + warningCount * 0.5) / total).clamp(0.0, 1.0);
    final percent = (score * 100).round();
    final lastSync = state.readings.isEmpty
        ? DateTime.now()
        : state.readings.map((r) => r.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$percent%',
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 97,
                        fontWeight: FontWeight.w900,
                        height: 0.9,
                        letterSpacing: -4,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                _TimeAgoLive(timestamp: lastSync),
              ],
            ),
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Greenhouse Status',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                Text(
                  _getStatusText(percent),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _AlertsSummaryCard(
              alertCount: alertCount,
              isAtRisk: alertCount > 0,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StableSensorsCard(normalCount: normalCount),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _WarningSensorsCard(warningCount: warningCount),
                      const SizedBox(height: 12),
                      _MonitoredSensorsCard(total: total),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _OverallSummaryCard(
              alertCount: alertCount,
              summary: alertCount > 0
                  ? 'Greenhouse is currently experiencing anomalies. $alertCount sensor readings are outside target thresholds. Please review warning telemetry.'
                  : 'System stability is highly optimal. Monitored indicators are well within ideal ranges. Active relays are managing current loads.',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getStatusText(int percent) {
    if (percent >= 90) return 'Excellent / Optimal';
    if (percent >= 75) return 'Ready / Healthy';
    if (percent >= 50) return 'Warning / At Risk';
    return 'Critical / Error';
  }

  Widget _buildSensorsSectionHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Row(
          children: [
            Text(
              'Sensors',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Spacer(),
            _ViewAnalyticsButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceStatusRow(AppState state) {
    final devices = state.devices;
    if (devices.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.bg1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.electrical_services, color: AppTheme.olive, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  devices.map((d) => '${d.label}: ${d.isOn ? 'ON' : 'OFF'}').join('  \u00B7  '),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBanner(BuildContext context, AppState state) {
    final alertSensors = state.readings
        .where((r) => r.status == SensorStatus.alert)
        .toList();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AlertsScreen(),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.alertSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.statusAlert.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppTheme.statusAlert, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${alertSensors.length} sensor${alertSensors.length > 1 ? "s" : ""} out of range: "
                    "${alertSensors.map((a) => a.label).join(', ')}",
                    style: const TextStyle(
                      color: AppTheme.statusAlert,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: AppTheme.statusAlert, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCards(BuildContext context, AppState state) {
    final readings = state.readings;
    if (readings.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text(
              'No sensor data available',
              style: TextStyle(
                color: AppTheme.inkFaint,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final reading = readings[index];
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
          childCount: readings.length,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// EXISTING WIDGETS (unchanged)
// ═══════════════════════════════════════════════════════════

class _TimeAgoLive extends StatefulWidget {
  final DateTime timestamp;

  const _TimeAgoLive({required this.timestamp});

  @override
  State<_TimeAgoLive> createState() => _TimeAgoLiveState();
}

class _TimeAgoLiveState extends State<_TimeAgoLive> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void didUpdateWidget(_TimeAgoLive old) {
    super.didUpdateWidget(old);
    if (old.timestamp != widget.timestamp) {
      setState(() => _now = DateTime.now());
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDiff(Duration diff) {
    final seconds = diff.inSeconds;
    if (seconds < 0) return 'Just now';
    if (seconds < 60) return '${seconds}s ago';
    if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s ago';
    if (seconds < 86400) return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m ago';
    return '${seconds ~/ 86400}d ${(seconds % 86400) ~/ 3600}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final diff = _now.difference(widget.timestamp);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Row(
        key: ValueKey<String>(_formatDiff(diff)),
        children: [
          const Icon(Icons.arrow_upward_rounded, color: AppTheme.statusNormal, size: 14),
          const SizedBox(width: 4),
          Text(
            _formatDiff(diff),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthGridShimmer extends StatelessWidget {
  const _HealthGridShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.bg2,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.bg2,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 196,
                  decoration: BoxDecoration(
                    color: AppTheme.bg2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 92,
                      decoration: BoxDecoration(
                        color: AppTheme.bg2,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 92,
                      decoration: BoxDecoration(
                        color: AppTheme.bg2,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertsSummaryCard extends StatelessWidget {
  final int alertCount;
  final bool isAtRisk;

  const _AlertsSummaryCard({
    required this.alertCount,
    required this.isAtRisk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.statusWarning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active Alerts',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$alertCount',
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sensors out of safe limits',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isAtRisk
                  ? AppTheme.statusAlert.withOpacity(0.15)
                  : AppTheme.statusNormal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isAtRisk ? 'AT RISK' : 'STABLE',
              style: TextStyle(
                color: isAtRisk ? AppTheme.statusAlert : AppTheme.statusNormal,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StableSensorsCard extends StatelessWidget {
  final int normalCount;

  const _StableSensorsCard({required this.normalCount});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        height: 196,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.statusNormal.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stable',
              style: TextStyle(
                color: AppTheme.statusNormal,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '$normalCount',
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sensors fully stable',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningSensorsCard extends StatelessWidget {
  final int warningCount;

  const _WarningSensorsCard({required this.warningCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.statusWarning.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Warning',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$warningCount',
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'at risk',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonitoredSensorsCard extends StatelessWidget {
  final int total;

  const _MonitoredSensorsCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.olive.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monitored',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.statusNormal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: AppTheme.statusNormal,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverallSummaryCard extends StatelessWidget {
  final int alertCount;
  final String summary;

  const _OverallSummaryCard({
    required this.alertCount,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppTheme.olive, size: 16),
              const SizedBox(width: 8),
              const Text(
                'OVERALL SUMMARY',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: alertCount > 0 ? AppTheme.statusAlert : AppTheme.statusNormal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewAnalyticsButton extends StatelessWidget {
  const _ViewAnalyticsButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.olive.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Analytics',
              style: TextStyle(
                color: AppTheme.olive,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward, color: AppTheme.olive, size: 14),
          ],
        ),
      ),
    );
  }
}