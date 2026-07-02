//scenario_video_player.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ScenarioVideoPlayer extends StatefulWidget {
  final String videoAsset;
  final VoidCallback? onInitialized;

  const ScenarioVideoPlayer({
    super.key,
    required this.videoAsset,
    this.onInitialized,
  });

  @override
  State<ScenarioVideoPlayer> createState() => _ScenarioVideoPlayerState();
}

class _ScenarioVideoPlayerState extends State<ScenarioVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(ScenarioVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoAsset != widget.videoAsset) {
      _disposeControllers();
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      _videoController = VideoPlayerController.asset(widget.videoAsset);
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: true,
        showControls: false,
        showOptions: false,
        allowFullScreen: false,
        allowMuting: false,
        allowPlaybackSpeedChanging: false,
        aspectRatio: _videoController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) => _buildErrorWidget(),
        placeholder: Container(color: Colors.black12),
      );

      setState(() => _isLoading = false);
      widget.onInitialized?.call();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _disposeControllers() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = null;
    _chewieController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black12,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 40),
            SizedBox(height: 8),
            Text(
              'Video failed to load',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return _buildErrorWidget();
    if (_isLoading || _chewieController == null) {
      return Container(
        color: Colors.black12,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Chewie(controller: _chewieController!),
    );
  }
}