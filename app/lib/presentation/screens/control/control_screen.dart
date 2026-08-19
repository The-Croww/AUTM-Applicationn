import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:automato/domain/models/sensor_data.dart';
import 'package:automato/presentation/providers/device_provider.dart';
import 'package:automato/presentation/providers/sensor_provider.dart';
import 'package:automato/presentation/theme/app_theme.dart';
import 'package:automato/presentation/widgets/sensor_card.dart'; // To reuse FloatingCard

// ─────────────────────────────────────────────────────────────
// CONTROL SCREEN — FLOATING MINIMALIST MODERN EDITION
// ─────────────────────────────────────────────────────────────

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final sensorProvider = context.watch<SensorProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EE), // Matching warm concrete paper canvas background
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            // ── Section 1: Device Control ───────────────────────────
            _buildSectionHeader('Device Control'),
            const SizedBox(height: 14),

            ...deviceProvider.devices.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DeviceCard(
                    device: d,
                    onStatusChanged: (status, isOn) =>
                        deviceProvider.setDeviceStatus(d.id, status, isOn),
                  ),
                )),
            const SizedBox(height: 16),

            // ── Emergency Shutdown Button (Positioned below Device Control) ──
            _buildEmergencyShutdownButton(context, deviceProvider, sensorProvider),
            const SizedBox(height: 32),

            // ── Section 2: Automation Rules ─────────────────────────
            _buildSectionHeader('Automation Rules'),
            const SizedBox(height: 14),

            ...deviceProvider.automationRules.map((rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RuleCard(
                    rule: rule,
                    readings: sensorProvider.readings,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.ink,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // EMERGENCY SHUTDOWN BUTTON — TACTICAL SAFETY FEATURE
  // ═══════════════════════════════════════════════════════════
  Widget _buildEmergencyShutdownButton(BuildContext context, DeviceProvider deviceProvider, SensorProvider sensorProvider) {
    final activeDevicesCount = deviceProvider.devices.where((d) => d.isOn).length;

    return FloatingCard(
      onTap: () => _showShutdownConfirmation(context, deviceProvider),
      backgroundColor: const Color(0xFFFAEAEA), // Extremely soft warning rose
      borderRadius: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFF5D4D4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.power_settings_new_rounded,
                color: AppTheme.statusAlert,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EMERGENCY SHUTDOWN',
                    style: TextStyle(
                      color: AppTheme.statusAlert,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    activeDevicesCount > 0
                        ? 'Deactivate all $activeDevicesCount running power relays immediately.'
                        : 'Deactivate all power grids & actuators.',
                    style: const TextStyle(
                      color: Color(0xFF8B3A3A),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.statusAlert,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Display a premium custom confirmation dialog to prevent accidental triggers
  void _showShutdownConfirmation(BuildContext context, DeviceProvider deviceProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.statusAlert),
              SizedBox(width: 8),
              Text(
                'Confirm Shutdown',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: const Text(
            'This action will instantly FORCE OFF all automated relays, water pumps, cooling fans, and lighting grids in the greenhouse.\n\nAre you sure you want to proceed?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.inkFaint, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                for (final device in deviceProvider.devices) {
                  deviceProvider.setDeviceStatus(device.id, DeviceStatus.manualOff, false);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('EMERGENCY SHUTDOWN ACTIVATED - ALL RELAYS OFF'),
                    backgroundColor: AppTheme.statusAlert,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusAlert,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'FORCE STOP',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── DEVICE CARD ──────────────────────────────────────────────
class _DeviceCard extends StatelessWidget {
  final DeviceState device;
  final void Function(DeviceStatus, bool) onStatusChanged;

  const _DeviceCard({
    required this.device,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = device.isOn;
    final activeColor = isOn ? const Color(0xFF132F28) : AppTheme.inkFaint;

    return FloatingCard(
      backgroundColor: Colors.white,
      borderRadius: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Row 1: Icon, Title and Current State Pill Badge
            Row(
              children: [
                Container(
                  width: 42,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isOn ? const Color(0xFFEAEFE4) : const Color(0xFFF4F2EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconData(device.icon),
                    color: isOn ? AppTheme.statusNormal : AppTheme.inkFaint,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.label,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (device.triggerReason != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          device.triggerReason!,
                          style: const TextStyle(
                            color: AppTheme.inkFaint,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isOn ? const Color(0xFFEAEFE4) : const Color(0xFFF4F2EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOn ? 'ACTIVE' : 'OFF',
                    style: TextStyle(
                      color: isOn ? AppTheme.statusNormal : AppTheme.inkFaint,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 2: Tactile Segmented Mode Selector Chips (Pill styled, no borders)
            Row(
              children: [
                Expanded(
                  child: _ModeChip(
                    label: 'AUTO',
                    selected: device.status == DeviceStatus.auto,
                    onTap: () => onStatusChanged(DeviceStatus.auto, isOn),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeChip(
                    label: 'ON',
                    selected: device.status == DeviceStatus.manualOn,
                    color: AppTheme.statusNormal,
                    onTap: () => onStatusChanged(DeviceStatus.manualOn, true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeChip(
                    label: 'OFF',
                    selected: device.status == DeviceStatus.manualOff,
                    color: AppTheme.statusAlert,
                    onTap: () => onStatusChanged(DeviceStatus.manualOff, false),
                  ),
                ),
              ],
            ),

            // Optional last triggered timestamp strip
            if (device.lastTriggered != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: AppTheme.inkFaint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Last active: ${_timeAgo(device.lastTriggered!)}',
                    style: const TextStyle(
                      color: AppTheme.inkFaint,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconData(String name) {
    switch (name) {
      case 'air':
        return Icons.air_rounded;
      case 'cyclone':
        return Icons.cyclone_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'light_mode':
        return Icons.light_mode_rounded;
      default:
        return Icons.power_rounded;
    }
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ── MODE CHIP (Pill Segmented Style) ──────────────────────────
class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF132F28);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha:0.12) : const Color(0xFFF4F2EE),
          borderRadius: BorderRadius.circular(20), // Premium pill shapes
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c : AppTheme.inkFaint,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ── AUTOMATION RULE CARD ─────────────────────────────────────
class _RuleCard extends StatelessWidget {
  final AutomationRule rule;
  final List<SensorReading> readings;

  const _RuleCard({
    required this.rule,
    required this.readings,
  });

  @override
  Widget build(BuildContext context) {
    final sensor = readings
        .where((r) => r.id == rule.sensorId)
        .firstOrNull;
    final isTriggered =
        sensor != null && sensor.status != SensorStatus.normal;

    return FloatingCard(
      backgroundColor: Colors.white,
      borderRadius: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTriggered ? AppTheme.statusWarning : const Color(0xFF132F28),
                boxShadow: isTriggered
                    ? [
                        BoxShadow(
                          color: AppTheme.statusWarning.withValues(alpha:0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            Expanded(
              child: Text(
                rule.actionDescription,
                style: const TextStyle(
                  color: AppTheme.inkMid,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}