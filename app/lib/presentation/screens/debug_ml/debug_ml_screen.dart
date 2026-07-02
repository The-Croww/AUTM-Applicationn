//debug_ml_screen.dart

import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/models.dart';
import '../../../presentation/providers/app_state.dart';
import '../../../services/vision_service.dart';
import '../../../services/google_drive_service.dart';

class DebugMLScreen extends StatefulWidget {
  const DebugMLScreen({super.key});

  @override
  State<DebugMLScreen> createState() => _DebugMLScreenState();
}

class _DebugMLScreenState extends State<DebugMLScreen> {
  bool _isLoading = false;
  VisionResult? _lastResult;
  String? _error;

  Future<void> _testVisionApi(PlantSnapshot snap) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _lastResult = null;
    });

    try {
      Uint8List imageBytes;
      if (snap.localPath != null && File(snap.localPath!).existsSync()) {
        imageBytes = await File(snap.localPath!).readAsBytes();
      } else if (snap.imageUrl != null) {
        final bytes = await GoogleDriveService().downloadImage(snap.imageUrl!);
        imageBytes = Uint8List.fromList(bytes);
      } else {
        throw Exception('No image data');
      }

      final result = await CloudVisionService().analyzePlantImage(imageBytes);

      setState(() {
        _lastResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

    /// Test Vision API with a sample plant image (no capture needed)
  Future<void> _testWithSampleImage() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _lastResult = null;
    });

    try {
      // Create a simple 100x100 green image as sample
      final bytes = await _generateSamplePlantImage();

      final result = await CloudVisionService().analyzePlantImage(bytes);

      setState(() {
        _lastResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Generate a simple green square image for testing
  Future<Uint8List> _generateSamplePlantImage() async {
    // Simple 100x100 green PNG bytes (base64 decoded)
    // This is a minimal valid PNG - green square
    const String base64Png = 
      'iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAABHNCSVQICAgIfAhkiAAAAElJREFUeJzt0EENwCAQwEDoH9rDfTEJCKG6Z+bMzDwA7zrf+wEAAAAAAADgT6vq9gEAAAAAAADgT6vq9gEAAAAAAADgT6vq9gEAAAAAAADgT6vq9gEAAAAAAADgT6vq9gH8WQAAAABJRU5ErkJggg==';
    return base64Decode(base64Png);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currentDay = state.currentDaySet;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EE),
      appBar: AppBar(
        title: const Text('ML Debug', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF4F2EE),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Test buttons for each slot
          const Text(
            'TEST VISION API',
            style: TextStyle(
              color: Color(0xFF132F28),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...[CaptureSlot.morning, CaptureSlot.afternoon, CaptureSlot.evening].map((slot) {
            final snap = currentDay.snapshots[slot];
            final hasImage = snap != null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedButton(
                onPressed: hasImage && !_isLoading ? () => _testVisionApi(snap!) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasImage ? const Color(0xFF132F28) : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasImage ? Icons.camera_alt : Icons.camera_alt_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Test ${slot.label} Image',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 16),

          // Fallback: Test without existing image
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _testWithSampleImage(),
            icon: const Icon(Icons.image_search, size: 18),
            label: const Text(
              'Test with Sample Plant Image',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1CA37B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 24),

          // Loading
          if (_isLoading) ...[
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF0F9F72)),
                  SizedBox(height: 12),
                  Text('Analyzing with Cloud Vision...', style: TextStyle(color: Color(0xFF132F28))),
                ],
              ),
            ),
          ],

          // Error
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error_outline, color: Color(0xFFC62828)),
                      SizedBox(width: 8),
                      Text(
                        'ERROR',
                        style: TextStyle(
                          color: Color(0xFFC62828),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFC62828)),
                  ),
                ],
              ),
            ),
          ],

          // Results
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(_lastResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(VisionResult result) {
    final features = result.toMLFeatures();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Raw Vision Labels
        _buildSectionCard(
          title: 'RAW VISION LABELS',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: result.labels.map((label) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F9F72),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF132F28),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Color Analysis
        _buildSectionCard(
          title: 'COLOR ANALYSIS',
          child: Column(
            children: [
              _buildScoreBar('Green', result.colors.greenScore, const Color(0xFF0F9F72)),
              const SizedBox(height: 8),
              _buildScoreBar('Yellow', result.colors.yellowScore, const Color(0xFFE8A838)),
              const SizedBox(height: 8),
              _buildScoreBar('Brown/Necrotic', result.colors.brownScore, const Color(0xFF8B4A00)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Local Analysis Scores (NEW)
        if (result.localScores != null) ...[
          _buildSectionCard(
            title: 'LOCAL ANALYSIS (PIXEL-LEVEL)',
            child: Column(
              children: [
                _buildScoreBar('Health Score', result.localScores!.healthScore, const Color(0xFF0F9F72)),
                const SizedBox(height: 8),
                _buildScoreBar('Vigor Score', result.localScores!.vigorScore, const Color(0xFF1CA37B)),
                const SizedBox(height: 8),
                _buildScoreBar('Dark Spots', result.localScores!.darkSpotScore, const Color(0xFF8B4A00)),
                const SizedBox(height: 8),
                _buildScoreBar('Brightness', result.localScores!.brightnessScore, const Color(0xFFE8A838)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F2EE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _colorDot('R', result.localScores!.avgR, const Color(0xFFE53935)),
                      _colorDot('G', result.localScores!.avgG, const Color(0xFF43A047)),
                      _colorDot('B', result.localScores!.avgB, const Color(0xFF1E88E5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ML Features
        _buildSectionCard(
          title: 'ML FEATURES (FUSED)',
          child: Column(
            children: [
              _buildScoreBar('Leaf Health', features.leafHealthScore, const Color(0xFF0F9F72)),
              const SizedBox(height: 8),
              _buildScoreBar('Color Index', features.colorIndex, const Color(0xFF1CA37B)),
              const SizedBox(height: 8),
              _buildScoreBar('Stem Vigor', features.stemVigor, const Color(0xFF132F28)),
              const SizedBox(height: 8),
              _buildScoreBar('Pest Severity', features.pestSeverity, const Color(0xFFE8A838)),
              if (features.detectedPests.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: features.detectedPests.map((pest) {
                    return Chip(
                      label: Text(
                        pest,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: const Color(0xFFE8A838),
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Growth Stage: ${features.growthStage}',
                style: const TextStyle(
                  color: Color(0xFF132F28),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // API Confidence
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: result.confidence > 0.7 ? const Color(0xFFEAEFE4) : const Color(0xFFFFF7EF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                result.confidence > 0.7 ? Icons.check_circle : Icons.warning_amber,
                color: result.confidence > 0.7 ? const Color(0xFF0F9F72) : const Color(0xFFE8A838),
              ),
              const SizedBox(width: 8),
              Text(
                'API Confidence: ${(result.confidence * 100).round()}%',
                style: TextStyle(
                  color: result.confidence > 0.7 ? const Color(0xFF0F9F72) : const Color(0xFF8B4A00),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _colorDot(String label, double value, Color color) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity((value / 255).clamp(0.1, 1.0)),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF132F28),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value.round().toString(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF132F28),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, double score, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF132F28),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: const Color(0xFFF4F2EE),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${score.round()}%',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
