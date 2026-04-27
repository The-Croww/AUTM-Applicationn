import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: AppTheme.bg0,
          child: TabBar(
            controller: _tabs,
            labelColor: AppTheme.textPrimary,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.textPrimary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: "Today's Captures"),
              Tab(text: 'Growth Timeline'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _TodayCapturesTab(),
              _GrowthTimelineTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── TODAY'S CAPTURES ──────────────────────────────────────────
class _TodayCapturesTab extends StatelessWidget {
  const _TodayCapturesTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = state.todayImageSet;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildScheduleHeader(state),
        const SizedBox(height: 16),
        _buildCaptureRow(today),
        const SizedBox(height: 20),
        if (today.isComplete && today.aiReport != null)
          _buildAICard(today.aiReport!)
        else
          _buildPendingAnalysis(today),
        const SizedBox(height: 20),
        _buildManualCapture(context, state),
        if (state.manualSnapshots.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildManualGallery(state),
        ],
      ],
    );
  }

  Widget _buildScheduleHeader(AppState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Scheduled captures: 6AM • 2PM • 10PM',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(state.nextCaptureLabel(),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureRow(DailyImageSet today) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Day ${today.dayNumber} — ${_dateLabel(today.date)}',
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: CaptureSlot.values.map((slot) {
            final snap = today.snapshots[slot];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CaptureThumbnail(slot: slot, snapshot: snap),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAICard(AIGrowthReport report) {
    final color = healthColor(report.healthStatus);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology_outlined, color: color, size: 14),
                    const SizedBox(width: 5),
                    Text('AI Analysis', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Spacer(),
              Text(report.scoreTrend,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text('${report.growthScore}%',
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          // Growth score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: report.growthScore / 100,
              backgroundColor: AppTheme.bg3,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _AIChip('Health', report.healthLabel, color),
              const SizedBox(width: 8),
              if (report.previousDayScore != null)
                _AIChip('vs yesterday',
                    '${report.previousDayScore}% → ${report.growthScore}%',
                    AppTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 14),
          Text(report.summary,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          _aiDetail('Leaves', report.leafAssessment),
          _aiDetail('Color', report.colorAssessment),
          _aiDetail('Stem', report.stemAssessment),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bg2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppTheme.statusWarning, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(report.recommendations,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _AIChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(text: '$label: ',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          TextSpan(text: value,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _aiDetail(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAnalysis(DailyImageSet today) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_empty_outlined,
              color: AppTheme.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Analysis Pending',
                    style: TextStyle(color: AppTheme.textPrimary,
                        fontSize: 14, fontWeight: FontWeight.w500)),
                Text(
                  today.isComplete
                      ? 'Analysis is being generated…'
                      : '${3 - today.captureCount} capture${3 - today.captureCount > 1 ? "s" : ""} remaining today',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualCapture(BuildContext context, AppState state) {
    return GestureDetector(
      onTap: () {
        state.triggerManualCapture();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manual snapshot captured'),
            backgroundColor: AppTheme.bg2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bg2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, color: AppTheme.textSecondary, size: 18),
            SizedBox(width: 8),
            Text('Manual Capture',
                style: TextStyle(color: AppTheme.textSecondary,
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildManualGallery(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manual captures (${state.manualSnapshots.length})',
            style: const TextStyle(color: AppTheme.textPrimary,
                fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: state.manualSnapshots.length,
          itemBuilder: (_, i) {
            final snap = state.manualSnapshots[i];
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.bg2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image_outlined,
                      color: AppTheme.textMuted, size: 24),
                  const SizedBox(height: 4),
                  Text(_timeLabel(snap.capturedAt),
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _dateLabel(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';
  String _timeLabel(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
  static const _months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
}

// ── GROWTH TIMELINE ───────────────────────────────────────────
class _GrowthTimelineTab extends StatelessWidget {
  const _GrowthTimelineTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final timeline = state.growthTimeline;

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: timeline.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final set = timeline[i];
        return _TimelineEntry(
          imageSet: set,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => _DayDetailScreen(imageSet: set))),
        );
      },
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final DailyImageSet imageSet;
  final VoidCallback onTap;
  const _TimelineEntry({required this.imageSet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final report = imageSet.aiReport;
    final color = report != null ? healthColor(report.healthStatus) : AppTheme.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bg1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Day ${imageSet.dayNumber}',
                    style: const TextStyle(color: AppTheme.textPrimary,
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text(_dateLabel(imageSet.date),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const Spacer(),
                if (report != null) ...[
                  Text(report.scoreTrend,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text('${report.growthScore}%',
                      style: TextStyle(color: color, fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ] else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.bg3, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Partial', style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 16),
              ],
            ),
            const SizedBox(height: 10),
            // 3 thumbnail slots
            Row(
              children: CaptureSlot.values.map((slot) {
                final snap = imageSet.snapshots[slot];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _MiniThumbnail(slot: slot, captured: snap != null),
                  ),
                );
              }).toList(),
            ),
            if (report != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: report.growthScore / 100,
                  backgroundColor: AppTheme.bg3,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}';
  static const _months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
}

class _MiniThumbnail extends StatelessWidget {
  final CaptureSlot slot;
  final bool captured;
  const _MiniThumbnail({required this.slot, required this.captured});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: captured ? AppTheme.bg2 : AppTheme.bg0,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: captured ? AppTheme.textSecondary.withOpacity(0.2) : AppTheme.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(captured ? Icons.image_outlined : Icons.crop_free,
              color: captured ? AppTheme.textSecondary : AppTheme.textMuted, size: 18),
          const SizedBox(height: 2),
          Text(_slotLabel(slot),
              style: TextStyle(
                  color: captured ? AppTheme.textMuted : AppTheme.textMuted.withOpacity(0.5),
                  fontSize: 9)),
        ],
      ),
    );
  }

  String _slotLabel(CaptureSlot s) {
    switch (s) {
      case CaptureSlot.morning:   return '6AM';
      case CaptureSlot.afternoon: return '2PM';
      case CaptureSlot.evening:   return '10PM';
    }
  }
}

// ── CAPTURE THUMBNAIL (today) ──────────────────────────────────
class _CaptureThumbnail extends StatelessWidget {
  final CaptureSlot slot;
  final PlantSnapshot? snapshot;
  const _CaptureThumbnail({required this.slot, this.snapshot});

  @override
  Widget build(BuildContext context) {
    final captured = snapshot != null;
    return Column(
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: captured ? AppTheme.bg2 : AppTheme.bg1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: captured ? AppTheme.textSecondary.withOpacity(0.25) : AppTheme.divider),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(captured ? Icons.eco_outlined : Icons.camera_outlined,
                  color: captured ? AppTheme.statusNormal : AppTheme.textMuted, size: 28),
              if (captured)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppTheme.statusNormal),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(snapshot?.slotLabel ?? _slotLabel,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        Text(snapshot?.slotTime ?? '--:--',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      ],
    );
  }

  String get _slotLabel {
    switch (slot) {
      case CaptureSlot.morning:   return 'Morning';
      case CaptureSlot.afternoon: return 'Afternoon';
      case CaptureSlot.evening:   return 'Evening';
    }
  }
}

// ── DAY DETAIL SCREEN ─────────────────────────────────────────
class _DayDetailScreen extends StatelessWidget {
  final DailyImageSet imageSet;
  const _DayDetailScreen({required this.imageSet});

  @override
  Widget build(BuildContext context) {
    final report = imageSet.aiReport;
    return Scaffold(
      backgroundColor: AppTheme.bg0,
      appBar: AppBar(
        title: Text('Day ${imageSet.dayNumber} — ${_dateLabel(imageSet.date)}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Images
          Row(
            children: CaptureSlot.values.map((slot) {
              final snap = imageSet.snapshots[slot];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CaptureThumbnail(slot: slot, snapshot: snap),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (report != null) ...[
            _buildFullReport(report),
          ] else ...[
            const Center(
              child: Text('AI report not yet available for this day.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullReport(AIGrowthReport report) {
    final color = healthColor(report.healthStatus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.psychology_outlined,
                color: AppTheme.textSecondary, size: 18),
            const SizedBox(width: 8),
            const Text('AI Growth Report',
                style: TextStyle(color: AppTheme.textPrimary,
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${report.growthScore}%',
                style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Text(report.scoreTrend, style: const TextStyle(fontSize: 18)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: report.growthScore / 100,
            backgroundColor: AppTheme.bg3,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 16),
        _row('Health Status', report.healthLabel, color),
        if (report.previousDayScore != null)
          _row('vs Previous Day',
              '${report.previousDayScore}% → ${report.growthScore}%',
              AppTheme.textSecondary),
        const SizedBox(height: 16),
        const Text('Summary',
            style: TextStyle(color: AppTheme.textPrimary,
                fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(report.summary,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, height: 1.6)),
        const SizedBox(height: 16),
        const Text('Plant Assessment',
            style: TextStyle(color: AppTheme.textPrimary,
                fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _detail('Leaves', report.leafAssessment),
        _detail('Color', report.colorAssessment),
        _detail('Stem', report.stemAssessment),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bg2, borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: AppTheme.statusWarning, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recommendations',
                        style: TextStyle(color: AppTheme.textPrimary,
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(report.recommendations,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _detail(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(label,
                style: const TextStyle(color: AppTheme.textMuted,
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}