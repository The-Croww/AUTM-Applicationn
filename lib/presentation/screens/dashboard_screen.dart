import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:automato/domain/models/sensor_data.dart';
import 'package:automato/presentation/providers/app_state.dart';
import 'package:automato/presentation/theme/app_theme.dart';
import 'package:automato/presentation/widgets/sensor_card.dart';
import 'package:automato/presentation/screens/sensor_detail_screen.dart';
import 'package:automato/presentation/screens/alerts_screen.dart';

// ─────────────────────────────────────────────────────────────
// DASHBOARD — PREMIUM FLOATING MINIMALIST (PICTURE MATCH EDITION)
// ─────────────────────────────────────────────────────────────

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EE), // Exact warm concrete paper tone from mockup
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            buildGreenhouseHealthStatus(state),
            if (state.alertCount > 0)
              buildAlertBanner(context, state),
            buildSensorsSectionHeader(),
            buildSensorCards(context, state),
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GREENHOUSE HEALTH STATUS — Showcase Dashboard Grid
  // Exact replication of the layout and styling in the attached image
  // ═══════════════════════════════════════════════════════════
  Widget buildGreenhouseHealthStatus(AppState state) {
    final total = state.readings.length;
    if (total == 0) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final alertCount = state.readings.where((r) => r.status == SensorStatus.alert).length;
    final warningCount = state.readings.where((r) => r.status == SensorStatus.warning).length;
    final normalCount = state.readings.where((r) => r.status == SensorStatus.normal).length;

    final score = ((normalCount * 1.0 + warningCount * 0.5) / total).clamp(0.0, 1.0);
    final percent = (score * 100).round();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Spacer to separate from device notch nicely
            const SizedBox(height: 12),

            // ── Giant Percentage & Sparkline Label ───────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 10, 10, 10), // Emerald green from image
                    fontSize: 97,
                    fontWeight: FontWeight.w900,
                    height: 0.9,
                    letterSpacing: -4,
                  ),
                ),
                const Spacer(),
                const Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded, color: Color(0xFF0F9F72), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'This week', // Exact label from image
                      style: TextStyle(
                        color: Color(0xFF706F69), // Muted slate gray
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Status: Muted Double Line (Moved below the percentage) ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Greenhouse Status.',
                  style: TextStyle(
                    color: Color(0xFF706F69), // Exact color from mockup
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                Text(
                  getPipelineStatusText(percent), // Dynamic conditional status based on percentage
                  style: const TextStyle(
                    color: Color(0xFF706F69),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Row 3: Wide Card (Active roles equivalent - Light Green) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFA5DD9B), // Bright light green from mockup
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
                        'Active alerts.',
                        style: TextStyle(
                          color: Color(0xFF132F28), // Deep forest green text
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$alertCount',
                        style: const TextStyle(
                          color: Color(0xFF132F28),
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sensors out of safe limits',
                        style: TextStyle(
                          color: Color(0xFF132F28),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132F28).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alertCount > 0 ? 'AT RISK' : 'STABLE',
                      style: const TextStyle(
                        color: Color(0xFF132F28),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Row 4: Asymmetric Grid Layout ───────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tall Left Card (Deep Green) ──────────────────────
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 196,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132F28), // Deep forest pine green from mockup
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reviewed.',
                          style: TextStyle(
                            color: Color(0xFFA5DD9B), // Light green text on deep green card
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$normalCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sensors fully stable',
                          style: TextStyle(
                            color: Color(0xFFA5DD9B),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Stacked Right Cards (Vibrant Teal/Green) ─────────
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Top Right Card (Pipeline equivalent)
                      Container(
                        height: 92,
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1CA37B), // Vibrant green from mockup
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Warning',
                              style: TextStyle(
                                color: Colors.white,
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
                                    color: Colors.white,
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
                                      color: Color(0xFFA5DD9B),
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
                      ),
                      const SizedBox(height: 12),

                      // Bottom Right Card (Shortlist equivalent)
                      Container(
                        height: 92,
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1CA37B), // Vibrant green from mockup
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Monitored',
                              style: TextStyle(
                                color: Colors.white,
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
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA5DD9B), // Light green pill
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Color(0xFF132F28), // Deep forest text
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Greenhouse Overall Summary Card (Positioned below asymmetric grid) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, // Pure white floating canvas
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03), // Soft floating ambient shadow
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
                      const Icon(Icons.analytics_outlined, color: Color(0xFF1CA37B), size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'OVERALL SUMMARY',
                        style: TextStyle(
                          color: Color(0xFF132F28),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      // Micro status dot indicator
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
                    alertCount > 0
                        ? 'Greenhouse is currently experiencing anomalies. $alertCount sensor readings are outside target thresholds. Please review warning telemetry.'
                        : 'System stability is highly optimal. Monitored indicators (Temperature, Humidity, CO2, Soil Moisture) are well within ideal ranges. Active relays are managing current loads.',
                    style: const TextStyle(
                      color: Color(0xFF706F69),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SENSORS SECTION HEADER
  // ═══════════════════════════════════════════════════════════
  Widget buildSensorsSectionHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Text(
          'Sensors',
          style: TextStyle(
            color: AppTheme.ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ALERT BANNER
  // ═══════════════════════════════════════════════════════════
  Widget buildAlertBanner(BuildContext context, AppState state) {
    final alertSensors = state.readings
        .where((r) => r.status == SensorStatus.alert)
        .toList();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
        child: FloatingCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AlertsScreen()),
          ),
          backgroundColor: AppTheme.alertSurface,
          borderRadius: 12.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  // ═══════════════════════════════════════════════════════════
  // SENSOR CARDS
  // ═══════════════════════════════════════════════════════════
  Widget buildSensorCards(BuildContext context, AppState state) {
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

  // ═══════════════════════════════════════════════════════════
  // CONDITIONAL PIPELINE STATUS TEXT
  // ═══════════════════════════════════════════════════════════
  String getPipelineStatusText(int percent) {
    if (percent >= 90) {
      return 'Excellent / Optimal'; // Excellent / Optimal (Good)
    } else if (percent >= 75) {
      return 'Ready / Healthy'; // Ready / Healthy (Good)
    } else if (percent >= 50) {
      return 'Warning / At Risk'; // Warning / At Risk (Bad)
    } else {
      return 'Critical / Error'; // Critical / Error (Bad)
    }
  }

  String fmt(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return 'Updated $h:$m:$s';
  }
}