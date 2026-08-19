//ml_debug_screen.dart

import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/models.dart';
import 'package:automato/presentation/providers/capture_provider.dart';
import 'package:automato/presentation/providers/growth_provider.dart';

class MLDebugScreen extends StatefulWidget {
  const MLDebugScreen({super.key});

  @override
  State<MLDebugScreen> createState() => _MLDebugScreenState();
}

class _MLDebugScreenState extends State<MLDebugScreen> {
  bool _isLoading = false;
  MLPlantFeatures? _lastFeatures;
  String? _error;

  Future<void> _testInference(PlantSnapshot snap) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _lastFeatures = null;
    });

    try {
      Uint8List imageBytes;
      if (snap.localPath != null && File(snap.localPath!).existsSync()) {
        imageBytes = await File(snap.localPath!).readAsBytes();
      } else {
        throw Exception('No image data');
      }

      final mlService = context.read<GrowthProvider>().mlInferenceService;
      final features = await mlService.analyzeImage(imageBytes);

      setState(() {
        _lastFeatures = features;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = context.watch<CaptureProvider>().currentDaySet;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EE),
      appBar: AppBar(
        title: const Text('ML Debug', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF4F2EE),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'TEST INFERENCE SERVICE',
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
                onPressed: hasImage && !_isLoading ? () => _testInference(snap!) : null,
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

          const SizedBox(height: 24),

          if (_isLoading) ...[
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF0F9F72)),
                  SizedBox(height: 12),
                  Text('Running inference...', style: TextStyle(color: Color(0xFF132F28))),
                ],
              ),
            ),
          ],

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

          if (_lastFeatures != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(_lastFeatures!),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(MLPlantFeatures features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: 'INFERENCE LABELS',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: features.labels.map((label) {
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

        _buildSectionCard(
          title: 'ML FEATURES',
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
            color: Colors.black.withValues(alpha:0.04),
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
