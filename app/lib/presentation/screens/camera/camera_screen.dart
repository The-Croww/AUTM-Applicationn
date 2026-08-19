//camera_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:automato/domain/models/sensor_data.dart';
import 'package:automato/presentation/providers/capture_provider.dart';
import 'package:automato/presentation/providers/growth_provider.dart';
import 'package:automato/presentation/theme/app_theme.dart';
import 'package:automato/presentation/widgets/sensor_card.dart';

import 'dart:typed_data';
import 'dart:io';
import '../debug_ml/debug_ml_screen.dart';

// ─────────────────────────────────────────────────────────────
// CAMERA FEED SCREEN
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
      backgroundColor: const Color(0xFFF4F2EE),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E2DC),
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
                        color: Colors.black.withValues(alpha:0.04),
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
                    Tab(text: "Day View"),
                    Tab(text: 'Growth Timeline'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  _DayViewTab(),
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
// DAY VIEW TAB
// ─────────────────────────────────────────────────────────────
class _DayViewTab extends StatelessWidget {
  const _DayViewTab();

  Future<void> _captureSlot(BuildContext context, CaptureProvider captureProvider, CaptureSlot slot) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );
    if (image == null) return;

    String? localPath;

    try {
      final Uint8List imageBytes = await image.readAsBytes();
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${slot.name}_${captureProvider.todayImageSet.dayNumber}_$timestamp.jpg';
      final String capturesDir = path.join(appDir.path, 'captures');
      localPath = path.join(capturesDir, fileName);
      
      await Directory(capturesDir).create(recursive: true);
      await File(localPath).writeAsBytes(imageBytes);

      await captureProvider.saveSlotCapture(
        slot: slot,
        bytes: imageBytes,
        localPath: localPath,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${slot.label} saved locally'),
            backgroundColor: AppTheme.statusWarning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (localPath != null) {
        try { File(localPath).deleteSync(); } catch (_) {}
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppTheme.statusAlert,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _replaceSlot(BuildContext context, CaptureProvider captureProvider, CaptureSlot slot, PlantSnapshot oldSnap) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE8A838)),
            SizedBox(width: 12),
            Text('Replace Capture?', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Text(
          'This will delete the current photo and regenerate AI analysis. Continue?',
          style: TextStyle(color: AppTheme.inkMid, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.inkFaint)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF132F28),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Replace', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );
    if (image == null) return;

    String? localPath;

    try {
      final Uint8List imageBytes = await image.readAsBytes();
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${slot.name}_${captureProvider.todayImageSet.dayNumber}_${timestamp}_replace.jpg';
      final String capturesDir = path.join(appDir.path, 'captures');
      localPath = path.join(capturesDir, fileName);
      
      await Directory(capturesDir).create(recursive: true);
      await File(localPath).writeAsBytes(imageBytes);

      await captureProvider.replaceSlotCapture(
        slot: slot,
        bytes: imageBytes,
        oldSnapshot: oldSnap,
        localPath: localPath,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Replaced successfully!'),
            backgroundColor: Color(0xFF0F9F72),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (localPath != null) {
        try { File(localPath).deleteSync(); } catch (_) {}
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to replace: $e'),
            backgroundColor: AppTheme.statusAlert,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _previewImage(BuildContext context, CaptureProvider captureProvider, PlantSnapshot snap, CaptureSlot slot) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.black,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(child: _buildFullImage(snap)),
                Container(
                  color: const Color(0xFF1A1A1A),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${slot.label} • ${snap.slotTime}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!snap.isManual && captureProvider.isViewingToday)
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _replaceSlot(context, captureProvider, slot, snap);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF132F28),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Replace',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullImage(PlantSnapshot snap) {
    if (snap.localPath != null && File(snap.localPath!).existsSync()) {
      return Image.file(File(snap.localPath!), fit: BoxFit.contain);
    }
    return const Center(child: Icon(Icons.broken_image, color: Colors.white));
  }

  @override
  Widget build(BuildContext context) {
    final captureProvider = context.watch<CaptureProvider>();
    final currentDay = captureProvider.currentDaySet;
    final isViewingToday = captureProvider.isViewingToday;

    final List<Widget> children = [
      _buildDayNavigator(context, captureProvider),
      const SizedBox(height: 20),
    ];

    if (isViewingToday) {
      children.addAll([
        _buildScheduleHeader(captureProvider),
        const SizedBox(height: 20),
      ]);
    }

    children.addAll([
      _buildCaptureRow(context, captureProvider, currentDay),
      const SizedBox(height: 24),
    ]);

    if (currentDay.isComplete && currentDay.aiReport != null) {
      children.add(_buildAICard(currentDay.aiReport!));
    } else {
      children.add(_buildPendingAnalysis(currentDay));
    }
    children.add(const SizedBox(height: 24));

    if (isViewingToday) {
      children.add(_buildManualCapture(context, captureProvider));
      if (captureProvider.manualSnapshots.isNotEmpty) {
        children.addAll([
          const SizedBox(height: 28),
          _buildManualGallery(captureProvider),
        ]);
      }
    }

    if (!isViewingToday && captureProvider.manualSnapshots.isNotEmpty) {
      children.addAll([
        const SizedBox(height: 28),
        _buildManualGallery(captureProvider),
      ]);
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      children: children,
    );
  }

  Widget _buildDayNavigator(BuildContext context, CaptureProvider captureProvider) {
    final currentDay = captureProvider.currentDaySet;
    final isViewingToday = captureProvider.isViewingToday;

    final hasPrev = currentDay.dayNumber > 1;
    final hasNext = currentDay.dayNumber < captureProvider.todayImageSet.dayNumber;
    
    return FloatingCard(
      backgroundColor: Colors.white,
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _DayNavButton(
              icon: Icons.chevron_left_rounded,
              isEnabled: hasPrev,
              onTap: hasPrev ? () => captureProvider.navigatePrevDay() : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _showDayPicker(context, captureProvider),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isViewingToday 
                        ? const Color(0xFFEAEFE4)
                        : const Color(0xFFF4F2EE),
                    borderRadius: BorderRadius.circular(10),
                    border: isViewingToday
                        ? Border.all(color: const Color(0xFF0F9F72), width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isViewingToday) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F9F72),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            'Day ${currentDay.dayNumber}'.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isViewingToday ? 'TODAY' : _dateLabel(currentDay.date),
                        style: TextStyle(
                          color: isViewingToday 
                              ? const Color(0xFF0F9F72)
                              : AppTheme.inkFaint,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _DayNavButton(
              icon: Icons.chevron_right_rounded,
              isEnabled: hasNext,
              onTap: hasNext ? () => captureProvider.navigateNextDay() : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showDayPicker(BuildContext context, CaptureProvider captureProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DayPickerSheet(
        captureProvider: captureProvider,
        onDaySelected: (dayNum) => captureProvider.navigateToDay(dayNum),
      ),
    );
  }

  Widget _buildScheduleHeader(CaptureProvider captureProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EFE9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E2DA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: Color(0xFF6B705C)),
          const SizedBox(width: 10),
          Text(
            'Next Capture: ${captureProvider.nextCaptureLabel()}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureRow(BuildContext context, CaptureProvider captureProvider, DailyImageSet daySet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Day ${daySet.dayNumber}'.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              _dateLabel(daySet.date),
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
          children: [CaptureSlot.morning, CaptureSlot.afternoon, CaptureSlot.evening].map((slot) {
            final snap = daySet.snapshots[slot];
            final isCaptured = snap != null;
            final isViewingToday = captureProvider.isViewingToday;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: slot != CaptureSlot.evening ? 10 : 0,
                ),
                child: _CaptureThumbnail(
                  slot: slot,
                  snapshot: snap,
                  isReadOnly: !isViewingToday,
                  onTap: isCaptured
                      ? () => _previewImage(context, captureProvider, snap!, slot)
                      : isViewingToday
                          ? () => _captureSlot(context, captureProvider, slot)
                          : null,
                ),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.08),
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
            _aiDetail('Leaves', report.leafAssessment),
            _aiDetail('Color', report.colorAssessment),
            _aiDetail('Stem', report.stemAssessment),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
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

  Widget _buildPendingAnalysis(DailyImageSet daySet) {
    final isComplete = daySet.isComplete;
    final remaining = 3 - daySet.captureCount;
    
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
              child: Icon(
                isComplete ? Icons.hourglass_empty_rounded : Icons.camera_alt_outlined,
                color: AppTheme.inkFaint,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isComplete ? 'AI Analysis Pending' : 'Captures Needed',
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isComplete
                        ? 'Analysis is being generated…'
                        : '$remaining capture${remaining > 1 ? "s" : ""} remaining',
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

  Widget _buildManualCapture(BuildContext context, CaptureProvider captureProvider) {
    return FloatingCard(
      onTap: () => _captureSlot(context, captureProvider, CaptureSlot.manual),
      backgroundColor: const Color(0xFF132F28),
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

  Widget _buildManualGallery(CaptureProvider captureProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MANUAL CAPTURES (${captureProvider.manualSnapshots.length})',
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
          itemCount: captureProvider.manualSnapshots.length,
          itemBuilder: (_, i) {
            final snap = captureProvider.manualSnapshots[i];
            return FloatingCard(
              backgroundColor: Colors.white,
              borderRadius: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildThumbnailImage(snap),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildThumbnailImage(PlantSnapshot snap) {
    if (snap.localPath != null && File(snap.localPath!).existsSync()) {
      return Image.file(
        File(snap.localPath!),
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
        cacheWidth: 300,
        cacheHeight: 300,
        errorBuilder: (_, __, ___) => _fallbackIcon(),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return const Center(
      child: Icon(
        Icons.image_outlined,
        color: Color(0xFF1CA37B),
        size: 24,
      ),
    );
  }

  String _dateLabel(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}

// ── Day Navigation Button ────────────────────────────────────
class _DayNavButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _DayNavButton({
    required this.icon,
    this.isEnabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFFF4F2EE) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isEnabled ? AppTheme.ink : AppTheme.inkGhost,
          size: 20,
        ),
      ),
    );
  }
}

// ── Day Picker Bottom Sheet ─────────────────────────────────
class _DayPickerSheet extends StatelessWidget {
  final CaptureProvider captureProvider;
  final Function(int) onDaySelected;

  const _DayPickerSheet({
    required this.captureProvider,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final todayNum = captureProvider.todayImageSet.dayNumber;
    final allDays = captureProvider.allDays;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E2DC),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'SELECT DAY',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: todayNum,
              itemBuilder: (_, i) {
                final dayNum = i + 1;
                final isToday = dayNum == todayNum;
                final hasData = allDays.any((d) => d.dayNumber == dayNum);
                final daySet = allDays.firstWhere(
                  (d) => d.dayNumber == dayNum,
                  orElse: () => DailyImageSet(
                    date: DateTime.now(),
                    dayNumber: dayNum,
                  ),
                );
                final captureCount = daySet.captureCount;
                
                return GestureDetector(
                  onTap: () {
                    onDaySelected(dayNum);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday 
                          ? const Color(0xFF0F9F72)
                          : hasData 
                              ? const Color(0xFFEAEFE4)
                              : const Color(0xFFF4F2EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                color: isToday ? Colors.white : AppTheme.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (hasData && !isToday)
                              Text(
                                '$captureCount/3',
                                style: const TextStyle(
                                  color: Color(0xFF0F9F72),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                        if (daySet.aiReport != null)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isToday ? Colors.white : const Color(0xFF0F9F72),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: const Color(0xFF0F9F72), label: 'Today'),
              const SizedBox(width: 16),
              _LegendDot(color: const Color(0xFFEAEFE4), label: 'Has data'),
              const SizedBox(width: 16),
              _LegendDot(color: const Color(0xFFF4F2EE), label: 'Empty'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.inkFaint,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GROWTH TIMELINE TAB
// ─────────────────────────────────────────────────────────────
class _GrowthTimelineTab extends StatelessWidget {
  const _GrowthTimelineTab();

  @override
  Widget build(BuildContext context) {
    final growthProvider = context.watch<GrowthProvider>();
    final timeline = growthProvider.growthTimeline;
    final totalDays = timeline.length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      children: [
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

// ── Growth Phase Header ─────────────────────────────────────
class _GrowthPhaseHeader extends StatelessWidget {
  final int totalDays;

  const _GrowthPhaseHeader({required this.totalDays});

  @override
  Widget build(BuildContext context) {
    String phaseTitle;
    String phaseDesc;
    double phaseProgress;
    String nextPhase;

    if (totalDays <= 7) {
      phaseTitle = 'Germination Stage';
      phaseDesc = 'Seed sprouted. Roots establishing in soil.';
      phaseProgress = totalDays / 7.0;
      nextPhase = 'Vegetative Stage';
    } else if (totalDays <= 25) {
      phaseTitle = 'Vegetative Phase';
      phaseDesc = 'Rapid leaf & stem expansion.';
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
            Container(
              width: double.infinity,
              height: 410,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F2EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Transform.scale(
                    scale: 3.2,
                    alignment: const Alignment(0.05, -0.1),
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

// ── Lottie Sprout Animation ─────────────────────────────────
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
    double progress;
    if (widget.totalDays <= 7) {
      progress = (widget.totalDays / 7.0) * 0.24;
    } else if (widget.totalDays <= 25) {
      progress = 0.24 + ((widget.totalDays - 7) / 18.0) * 0.30;
    } else if (widget.totalDays <= 45) {
      progress = 0.54 + ((widget.totalDays - 25) / 20.0) * 0.21;
    } else {
      progress = 0.75 + ((widget.totalDays - 45) / 15.0).clamp(0.0, 1.0) * 0.25;
    }

    return Lottie.asset(
      'assets/icon/tomato-growth.json',
      controller: _controller,
      onLoaded: (composition) {
        _controller.duration = composition.duration;
        _controller.value = progress.clamp(0.0, 1.0);
      },
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.local_florist_rounded,
          color: Color(0xFF0F9F72),
          size: 32,
        );
      },
    );
  }
}

// ── Timeline Entry ──────────────────────────────────────────
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
              children: [CaptureSlot.morning, CaptureSlot.afternoon, CaptureSlot.evening].map((slot) {
                final snap = imageSet.snapshots[slot];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: slot != CaptureSlot.evening ? 8 : 0,
                    ),
                    child: _MiniThumbnail(slot: slot, snapshot: snap),
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

// ── Mini Thumbnail (for timeline) ───────────────────────────
class _MiniThumbnail extends StatelessWidget {
  final CaptureSlot slot;
  final PlantSnapshot? snapshot;

  const _MiniThumbnail({
    required this.slot,
    this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final captured = snapshot != null;
    
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: captured ? Colors.white : const Color(0xFFF4F2EE),
        borderRadius: BorderRadius.circular(10),
        border: captured
            ? Border.all(color: const Color(0xFFEAEFE4), width: 1)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: captured
            ? _buildThumbnailImage(snapshot!)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.crop_free_rounded,
                    color: AppTheme.inkGhost,
                    size: 18,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    slot.labelShort,
                    style: TextStyle(
                      color: AppTheme.inkFaint,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildThumbnailImage(PlantSnapshot snap) {
    if (snap.localPath != null && File(snap.localPath!).existsSync()) {
      return Image.file(
        File(snap.localPath!),
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
        cacheWidth: 150,
        cacheHeight: 150,
        errorBuilder: (_, __, ___) => _fallbackIcon(),
      );
    }

    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          color: AppTheme.inkGhost,
          size: 16,
        ),
        const SizedBox(height: 2),
        Text(
          slot.labelShort,
          style: TextStyle(
            color: AppTheme.inkFaint,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── Capture Thumbnail (for day view) ────────────────────────
class _CaptureThumbnail extends StatelessWidget {
  final CaptureSlot slot;
  final PlantSnapshot? snapshot;
  final bool isReadOnly;
  final VoidCallback? onTap;

  const _CaptureThumbnail({
    required this.slot,
    this.snapshot,
    this.isReadOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final captured = snapshot != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 104,
            width: double.infinity,
            decoration: BoxDecoration(
              color: captured ? Colors.white : const Color(0xFFE5E2DC),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: captured
                  ? _buildCapturedThumbnail(snapshot!)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isReadOnly ? Icons.lock_outline : Icons.camera_alt_outlined,
                          color: AppTheme.inkFaint,
                          size: 26,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            snapshot?.slotLabel ?? slot.label,
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
      ),
    );
  }

  Widget _buildCapturedThumbnail(PlantSnapshot snap) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildThumbnailImage(snap),
        if (!isReadOnly)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha:0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnailImage(PlantSnapshot snap) {
    if (snap.localPath != null && File(snap.localPath!).existsSync()) {
      return Image.file(
        File(snap.localPath!),
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
        cacheWidth: 300,
        cacheHeight: 300,
        errorBuilder: (_, __, ___) => _fallbackIcon(),
      );
    }

    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return const Center(
      child: Icon(
        Icons.eco_rounded,
        color: Color(0xFF0F9F72),
        size: 26,
      ),
    );
  }
}

// ── Day Detail Screen ────────────────────────────────────────
class _DayDetailScreen extends StatelessWidget {
  final DailyImageSet imageSet;

  const _DayDetailScreen({required this.imageSet});

  @override
  Widget build(BuildContext context) {
    final report = imageSet.aiReport;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EE),
      appBar: AppBar(
        title: Text(
          'Day ${imageSet.dayNumber} — ${_dateLabel(imageSet.date)}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color(0xFFF4F2EE),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Color(0xFF132F28)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MLDebugScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [CaptureSlot.morning, CaptureSlot.afternoon, CaptureSlot.evening].map((slot) {
              final snap = imageSet.snapshots[slot];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: slot != CaptureSlot.evening ? 10 : 0,
                  ),
                  child: _CaptureThumbnail(
                    slot: slot,
                    snapshot: snap,
                    isReadOnly: true,
                    onTap: () {},
                  ),
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