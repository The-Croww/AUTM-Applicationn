import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; // Complete dynamic plant growth visualization
import 'package:image_picker/image_picker.dart'; // Add image_picker to open native camera instantly
import 'package:automato/domain/models/sensor_data.dart';
import 'package:automato/presentation/providers/app_state.dart';
import 'package:automato/presentation/theme/app_theme.dart';
import 'package:automato/presentation/widgets/sensor_card.dart'; // To reuse FloatingCard

// ─────────────────────────────────────────────────────────────
// CAMERA FEED SCREEN — FLOATING MINIMALIST MODERN EDITION
// ─────────────────────────────────────────────────────────────

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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EE), // Warm concrete paper background matching Dashboard
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // ── Premium Segmented Tab Selector ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E2DC), // Deep warm gray track
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabs,
                  labelColor: AppTheme.ink,
                  unselectedLabelColor: AppTheme.inkFaint,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: -0.1,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: "Today's Captures"),
                    Tab(text: 'Growth Timeline'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Viewport Tab Content ────────────────────────────────
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
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TODAY'S CAPTURES TAB
// ─────────────────────────────────────────────────────────────
class _TodayCapturesTab extends StatelessWidget {
  const _TodayCapturesTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = state.todayImageSet;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      children: [
        _buildScheduleHeader(state),
        const SizedBox(height: 24),
        _buildCaptureRow(today),
        const SizedBox(height: 24),
        if (today.isComplete && today.aiReport != null)
          _buildAICard(today.aiReport!)
        else
          _buildPendingAnalysis(today),
        const SizedBox(height: 24),
        _buildViewLive(context, state), // ── View Live Button ──
        const SizedBox(height: 12),
        _buildManualCapture(context, state),
        if (state.manualSnapshots.isNotEmpty) ...[
          const SizedBox(height: 28),
          _buildManualGallery(state),
        ],
      ],
    );
  }

  Widget _buildScheduleHeader(AppState state) {
    return FloatingCard(
      backgroundColor: Colors.white,
      borderRadius: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F2EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: Color(0xFF132F28),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scheduled captures: 6AM • 2PM • 10PM',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    state.nextCaptureLabel(),
                    style: const TextStyle(
                      color: AppTheme.inkFaint,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureRow(DailyImageSet today) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Day ${today.dayNumber}'.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              _dateLabel(today.date),
              style: const TextStyle(
                color: AppTheme.inkFaint,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: CaptureSlot.values.map((slot) {
            final snap = today.snapshots[slot];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: slot != CaptureSlot.values.last ? 10 : 0,
                ),
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
    return FloatingCard(
      backgroundColor: Colors.white,
      borderRadius: 8,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology_outlined, color: color, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'AI Analysis',
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  report.scoreTrend,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 4),
                Text(
                  '${report.growthScore}%',
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Growth Progress Indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: report.growthScore / 100,
                backgroundColor: const Color(0xFFF4F2EE),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 14),

            // AI Status chips
            Row(
              children: [
                _AIChip('Health', report.healthLabel, color),
                const SizedBox(width: 8),
                if (report.previousDayScore != null)
                  _AIChip(
                    'vs Yesterday',
                    '${report.previousDayScore}% → ${report.growthScore}%',
                    AppTheme.inkMid,
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Summary text
            Text(
              report.summary,
              style: const TextStyle(
                color: AppTheme.inkMid,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: AppTheme.divider, thickness: 1.2),
            const SizedBox(height: 12),

            // Diagnostic assessment outputs
            _aiDetail('Leaves', report.leafAssessment),
            _aiDetail('Color', report.colorAssessment),
            _aiDetail('Stem', report.stemAssessment),
            const SizedBox(height: 14),

            // Recommendations Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7EF), // Extremely soft warning/amber glow
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.statusWarning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Recommendation',
                          style: TextStyle(
                            color: AppTheme.statusWarning,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.recommendations,
                          style: const TextStyle(
                            color: Color(0xFF8B4A00),
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _AIChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F2EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppTheme.inkFaint,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiDetail(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.inkFaint,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.inkMid,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAnalysis(DailyImageSet today) {
    return FloatingCard(
      backgroundColor: Colors.white,
      borderRadius: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F2EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                color: AppTheme.inkFaint,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Analysis Pending',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    today.isComplete
                        ? 'Analysis is being generated…'
                        : '${3 - today.captureCount} capture${3 - today.captureCount > 1 ? "s" : ""} remaining today',
                    style: const TextStyle(
                      color: AppTheme.inkFaint,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // VIEW LIVE FEED BUTTON — OPENS NATIVE PHONE CAMERA
  // ═══════════════════════════════════════════════════════════
  Widget _buildViewLive(BuildContext context, AppState state) {
    return FloatingCard(
      onTap: () async {
        try {
          // Initialize ImagePicker to open the native system camera app instantly!
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(
            source: ImageSource.camera,
            preferredCameraDevice: CameraDevice.rear,
          );
          
          if (image != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Live Feed snapshot captured: ${image.name}'),
                backgroundColor: const Color(0xFF0F9F72),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open camera app: $e'),
              backgroundColor: AppTheme.statusAlert,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      backgroundColor: const Color(0xFF0F9F72), // Matches emerald green
      borderRadius: 14,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_outlined,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'VIEW LIVE FEED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualCapture(BuildContext context, AppState state) {
    return FloatingCard(
      onTap: () {
        state.triggerManualCapture();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manual snapshot captured'),
            backgroundColor: AppTheme.ink,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      backgroundColor: const Color(0xFF132F28), // Premium deep green tactical button
      borderRadius: 14,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'MANUAL CAPTURE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualGallery(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MANUAL CAPTURES (${state.manualSnapshots.length})',
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: state.manualSnapshots.length,
          itemBuilder: (_, i) {
            final snap = state.manualSnapshots[i];
            return FloatingCard(
              backgroundColor: Colors.white,
              borderRadius: 14,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.image_outlined,
                    color: Color(0xFF1CA37B),
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeLabel(snap.capturedAt),
                    style: const TextStyle(
                      color: AppTheme.inkMid,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}

// ─────────────────────────────────────────────────────────────
// GROWTH TIMELINE TAB (Interactive dynamic Lottie Plant Cycles)
// ─────────────────────────────────────────────────────────────
class _GrowthTimelineTab extends StatelessWidget {
  const _GrowthTimelineTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final timeline = state.growthTimeline;
    final totalDays = timeline.length; // Active crop days monitored

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      children: [
        // ── Dynamic interactive Lottie crop phase header ──
        _GrowthPhaseHeader(totalDays: totalDays),
        const SizedBox(height: 28),

        const Text(
          'GROWTH LOGS',
          style: TextStyle(
            color: AppTheme.ink,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),

        ...timeline.map((set) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _TimelineEntry(
              imageSet: set,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _DayDetailScreen(imageSet: set),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

// ── Interactive dynamic Lottie growth stage card (High Prominence Edition) ─────────
class _GrowthPhaseHeader extends StatelessWidget {
  final int totalDays;

  const _GrowthPhaseHeader({required this.totalDays});

  @override
  Widget build(BuildContext context) {
    String phaseTitle;
    String phaseDesc;
    double phaseProgress;
    String nextPhase;

    // Dynamically map exact crop days to agricultural stages
    if (totalDays <= 7) {
      phaseTitle = 'Germination Stage';
      phaseDesc = 'Seed sprouted. Roots establishing in soil.';
      phaseProgress = totalDays / 7.0;
      nextPhase = 'Vegetative Stage';
    } else if (totalDays <= 25) {
      phaseTitle = 'Vegetative Phase';
      phaseDesc = 'Rapid leaf & stem expansion. ESP32-Cam checking leaf cover.';
      phaseProgress = (totalDays - 7) / 18.0;
      nextPhase = 'Flowering Phase';
    } else if (totalDays <= 45) {
      phaseTitle = 'Flowering Stage';
      phaseDesc = 'Yellow blossom structures appearing. Ideal pollination.';
      phaseProgress = (totalDays - 25) / 20.0;
      nextPhase = 'Fruiting Stage';
    } else {
      phaseTitle = 'Fruiting Stage';
      phaseDesc = 'Ripe cherry tomatoes growing. Checking coloration index.';
      phaseProgress = 1.0;
      nextPhase = 'Harvest Ready';
    }

    return FloatingCard(
      backgroundColor: Colors.white,
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Part: Large, Zoomed-In Lottie Animation ──
            Container(
              width: double.infinity,
              height: 410, // Tall and prominent
              decoration: BoxDecoration(
                color: const Color(0xFFF4F2EE), // Soft neutral paper background matching dashboard
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Transform.scale(
                    scale: 3.2, // Generously scale up the sprout so it is big and visible
                    alignment: const Alignment(0.05, -0.1), // Perfect custom focal point: lifts the sprout up slightly so the bottom isn't cut off, while keeping it centered!
                    child: SizedBox(
                      width: double.infinity,
                      height: 220,
                      child: _LottieSproutAnimation(totalDays: totalDays),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Bottom Part: Growth Phase Info & Progress Indicator ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  phaseTitle,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEFE4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'STAGE ${totalDays <= 7 ? 1 : totalDays <= 25 ? 2 : totalDays <= 45 ? 3 : 4}'.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF132F28),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              phaseDesc,
              style: const TextStyle(
                color: AppTheme.inkMid,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            // Progress Bar Tracker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Day $totalDays active',
                  style: const TextStyle(
                    color: AppTheme.inkFaint,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Next: $nextPhase',
                  style: const TextStyle(
                    color: Color(0xFF1CA37B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: phaseProgress.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFF4F2EE),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F9F72)),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live Lottie Sprout Frame Control (Stateful Animation Controller) ─────────────────
class _LottieSproutAnimation extends StatefulWidget {
  final int totalDays;

  const _LottieSproutAnimation({required this.totalDays});

  @override
  State<_LottieSproutAnimation> createState() => _LottieSproutAnimationState();
}

class _LottieSproutAnimationState extends State<_LottieSproutAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculates plant progress matching composition frames (Total: 187 frames)
    double progress;
    if (widget.totalDays <= 7) {
      progress = (widget.totalDays / 7.0) * 0.24; // Sprouted
    } else if (widget.totalDays <= 25) {
      progress = 0.24 + ((widget.totalDays - 7) / 18.0) * 0.30; // Vegetative
    } else if (widget.totalDays <= 45) {
      progress = 0.54 + ((widget.totalDays - 25) / 20.0) * 0.21; // Flowering
    } else {
      progress = 0.75 + ((widget.totalDays - 45) / 15.0).clamp(0.0, 1.0) * 0.25; // Fruiting
    }

    return Lottie.asset(
      'assets/icon/tomato-growth.json',
      controller: _controller,
      onLoaded: (composition) {
        _controller.duration = composition.duration;
        // Snaps plant frame to exactly match live camera timeline situation!
        _controller.value = progress.clamp(0.0, 1.0);
      },
      fit: BoxFit.contain, // Maintain aspect ratio perfectly centered
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) {
        // Safe robust fallback in case of loading issues
        return const Icon(
          Icons.local_florist_rounded,
          color: Color(0xFF0F9F72),
          size: 32,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TIMELINE ENTRY LIST WIDGET
// ─────────────────────────────────────────────────────────────
class _TimelineEntry extends StatelessWidget {
  final DailyImageSet imageSet;
  final VoidCallback onTap;

  const _TimelineEntry({
    required this.imageSet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final report = imageSet.aiReport;
    final color = report != null
        ? healthColor(report.healthStatus)
        : AppTheme.inkFaint;

    return FloatingCard(
      onTap: onTap,
      backgroundColor: Colors.white,
      borderRadius: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Day ${imageSet.dayNumber}',
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _dateLabel(imageSet.date),
                  style: const TextStyle(
                    color: AppTheme.inkFaint,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (report != null) ...[
                  Text(report.scoreTrend, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    '${report.growthScore}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F2EE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Partial',
                      style: TextStyle(
                        color: AppTheme.inkFaint,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.inkFaint,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: CaptureSlot.values.map((slot) {
                final snap = imageSet.snapshots[slot];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: slot != CaptureSlot.values.last ? 8 : 0,
                    ),
                    child: _MiniThumbnail(slot: slot, captured: snap != null),
                  ),
                );
              }).toList(),
            ),
            if (report != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: report.growthScore / 100,
                  backgroundColor: const Color(0xFFF4F2EE),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _MiniThumbnail extends StatelessWidget {
  final CaptureSlot slot;
  final bool captured;

  const _MiniThumbnail({
    required this.slot,
    required this.captured,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: captured ? const Color(0xFFEAEFE4) : const Color(0xFFF4F2EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            captured ? Icons.image_outlined : Icons.crop_free_rounded,
            color: captured ? AppTheme.olive : AppTheme.inkGhost,
            size: 18,
          ),
          const SizedBox(height: 2),
          Text(
            _slotLabel(slot),
            style: TextStyle(
              color: captured ? AppTheme.olive : AppTheme.inkFaint,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _slotLabel(CaptureSlot s) {
    switch (s) {
      case CaptureSlot.morning:
        return '6AM';
      case CaptureSlot.afternoon:
        return '2PM';
      case CaptureSlot.evening:
        return '10PM';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// CAPTURE THUMBNAIL WIDGET (TODAY)
// ─────────────────────────────────────────────────────────────
class _CaptureThumbnail extends StatelessWidget {
  final CaptureSlot slot;
  final PlantSnapshot? snapshot;

  const _CaptureThumbnail({
    required this.slot,
    this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final captured = snapshot != null;
    return Column(
      children: [
        Container(
          height: 104,
          width: double.infinity,
          decoration: BoxDecoration(
            color: captured ? Colors.white : const Color(0xFFE5E2DC),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                captured ? Icons.eco_rounded : Icons.camera_alt_outlined,
                color: captured ? Color(0xFF0F9F72) : AppTheme.inkFaint,
                size: 26,
              ),
              if (captured)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0F9F72),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          snapshot?.slotLabel ?? _slotLabel,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          snapshot?.slotTime ?? '--:--',
          style: const TextStyle(
            color: AppTheme.inkFaint,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String get _slotLabel {
    switch (slot) {
      case CaptureSlot.morning:
        return 'Morning';
      case CaptureSlot.afternoon:
        return 'Afternoon';
      case CaptureSlot.evening:
        return 'Evening';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// DAY DETAIL SCREEN (Timeline Tap Navigation)
// ─────────────────────────────────────────────────────────────
class _DayDetailScreen extends StatelessWidget {
  final DailyImageSet imageSet;

  const _DayDetailScreen({required this.imageSet});

  @override
  Widget build(BuildContext context) {
    final report = imageSet.aiReport;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EE), // Matching theme background
      appBar: AppBar(
        title: Text(
          'Day ${imageSet.dayNumber} — ${_dateLabel(imageSet.date)}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color(0xFFF4F2EE),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: CaptureSlot.values.map((slot) {
              final snap = imageSet.snapshots[slot];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: slot != CaptureSlot.values.last ? 10 : 0,
                  ),
                  child: _CaptureThumbnail(slot: slot, snapshot: snap),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          if (report != null)
            _buildFullReport(report)
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'AI report not yet available for this day.',
                  style: TextStyle(
                    color: AppTheme.inkFaint,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFullReport(AIGrowthReport report) {
    final color = healthColor(report.healthStatus);
    return FloatingCard(
      backgroundColor: Colors.white,
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology_outlined,
                  color: AppTheme.inkMid,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI Growth Report',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '${report.growthScore}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  report.scoreTrend,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: report.growthScore / 100,
                backgroundColor: const Color(0xFFF4F2EE),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            _row('Health Status', report.healthLabel, color),
            if (report.previousDayScore != null)
              _row(
                'vs Previous Day',
                '${report.previousDayScore}% → ${report.growthScore}%',
                AppTheme.inkMid,
              ),
            const SizedBox(height: 16),
            const Text(
              'Summary',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              report.summary,
              style: const TextStyle(
                color: AppTheme.inkMid,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Plant Assessment',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            _detail('Leaves', report.leafAssessment),
            _detail('Color', report.colorAssessment),
            _detail('Stem', report.stemAssessment),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7EF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.statusWarning,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recommendations',
                          style: TextStyle(
                            color: AppTheme.statusWarning,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.recommendations,
                          style: const TextStyle(
                            color: Color(0xFF8B4A00),
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.inkMid,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
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
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.inkFaint,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.inkMid,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
