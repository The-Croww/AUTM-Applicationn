import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isStreaming = false;
  final List<_Snapshot> _snapshots = [];
  int _snapshotCount = 0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildFeedCard(),
        const SizedBox(height: 20),
        _buildSnapshotSection(),
      ],
    );
  }

  Widget _buildFeedCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Feed area
          AspectRatio(
            aspectRatio: 4 / 3,
            child: _isStreaming ? _buildMockStream() : _buildOfflineState(),
          ),

          // Controls bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _ControlButton(
                    icon: _isStreaming ? Icons.stop_circle_outlined : Icons.play_circle_outlined,
                    label: _isStreaming ? 'Stop stream' : 'Start stream',
                    primary: !_isStreaming,
                    onTap: () => setState(() => _isStreaming = !_isStreaming),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ControlButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Snapshot',
                    primary: false,
                    onTap: _isStreaming ? _takeSnapshot : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockStream() {
    // In real app: replace with WebView or Image.network(streamUrl, ...)
    return Stack(
      children: [
        Container(
          color: const Color(0xFF0D1A0D),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam,
                    size: 48,
                    color: AppTheme.textSecondary.withOpacity(0.15)),
                const SizedBox(height: 8),
                Text('ESP32-CAM stream',
                    style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.15), fontSize: 13)),
                Text('Replace with Image.network(streamUrl)',
                    style: TextStyle(
                        color: AppTheme.textMuted.withOpacity(0.6),
                        fontSize: 11)),
              ],
            ),
          ),
        ),
        // LIVE badge
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.statusAlert,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 6, color: Colors.white),
                SizedBox(width: 4),
                Text('LIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineState() {
    return Container(
      color: AppTheme.bg2,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, size: 48, color: AppTheme.textMuted),
            SizedBox(height: 8),
            Text('Stream offline',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
            SizedBox(height: 4),
            Text('Press "Start stream" to connect to ESP32-CAM',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Snapshots',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            if (_snapshots.isNotEmpty)
              Text('${_snapshots.length}',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        if (_snapshots.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.bg1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: const Center(
              child: Text('No snapshots yet.\nStart the stream and tap "Snapshot".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.6)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _snapshots.length,
            itemBuilder: (context, i) => _SnapshotTile(snapshot: _snapshots[i]),
          ),
      ],
    );
  }

  void _takeSnapshot() {
    setState(() {
      _snapshotCount++;
      _snapshots.insert(
        0,
        _Snapshot(
          id: _snapshotCount,
          timestamp: DateTime.now(),
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Snapshot saved'),
        backgroundColor: AppTheme.bg2,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: primary && enabled
              ? AppTheme.textSecondary.withOpacity(0.15)
              : AppTheme.bg3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primary && enabled
                ? AppTheme.textSecondary.withOpacity(0.15)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: enabled
                    ? (primary ? AppTheme.textPrimary : AppTheme.textSecondary)
                    : AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  color: enabled
                      ? (primary ? AppTheme.textPrimary : AppTheme.textSecondary)
                      : AppTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

class _Snapshot {
  final int id;
  final DateTime timestamp;
  _Snapshot({required this.id, required this.timestamp});
}

class _SnapshotTile extends StatelessWidget {
  final _Snapshot snapshot;
  const _SnapshotTile({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Icon(Icons.image, color: AppTheme.textMuted, size: 28),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Text(
              _fmt(snapshot.timestamp),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}