import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader('Device Control'),
            const SizedBox(height: 12),
            ...state.devices.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DeviceCard(
                    device: d,
                    onStatusChanged: (status, isOn) =>
                        state.setDeviceStatus(d.id, status, isOn),
                  ),
                )),
            const SizedBox(height: 24),
            _buildSectionHeader('Automation Rules'),
            const SizedBox(height: 12),
            ...state.automationRules.map((rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RuleCard(rule: rule, readings: state.readings),
                )),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final DeviceState device;
  final void Function(DeviceStatus, bool) onStatusChanged;

  const _DeviceCard({required this.device, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    final isOn = device.isOn;
    final activeColor = isOn ? AppTheme.textPrimary : AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOn ? AppTheme.textSecondary.withOpacity(0.3) : AppTheme.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconData(device.icon), color: activeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.label,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                    if (device.triggerReason != null)
                      Text(device.triggerReason!,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOn ? 'ON' : 'OFF',
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ModeChip(
                label: 'AUTO',
                selected: device.status == DeviceStatus.auto,
                onTap: () => onStatusChanged(DeviceStatus.auto, isOn),
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: 'FORCE ON',
                selected: device.status == DeviceStatus.manualOn,
                color: AppTheme.textPrimary,
                onTap: () => onStatusChanged(DeviceStatus.manualOn, true),
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: 'FORCE OFF',
                selected: device.status == DeviceStatus.manualOff,
                color: AppTheme.statusAlert,
                onTap: () => onStatusChanged(DeviceStatus.manualOff, false),
              ),
            ],
          ),
          if (device.lastTriggered != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, size: 11, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Last triggered: ${_timeAgo(device.lastTriggered!)}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconData(String name) {
    switch (name) {
      case 'air':        return Icons.air;
      case 'cyclone':    return Icons.cyclone;
      case 'water':      return Icons.water;
      case 'light_mode': return Icons.light_mode;
      default:           return Icons.power;
    }
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

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
    final c = color ?? AppTheme.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.15) : AppTheme.bg3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? c.withOpacity(0.4) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c : AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final AutomationRule rule;
  final List<SensorReading> readings;

  const _RuleCard({required this.rule, required this.readings});

  @override
  Widget build(BuildContext context) {
    final sensor = readings.where((r) => r.id == rule.sensorId).firstOrNull;
    final isTriggered = sensor != null && sensor.status != SensorStatus.normal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTriggered ? AppTheme.statusWarning : AppTheme.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              rule.actionDescription,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}