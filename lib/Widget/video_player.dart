import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final CachedVideoPlayerPlusController? externalController;
  final bool initializeWhenExternalMissing;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.externalController,
    this.initializeWhenExternalMissing = true,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  CachedVideoPlayerPlusController? _internalController;
  CachedVideoPlayerPlusController? _loopGuardController;
  VoidCallback? _loopGuardListener;
  bool _isRestartingLoop = false;

  CachedVideoPlayerPlusController get _controller =>
      widget.externalController ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.externalController == null &&
        widget.initializeWhenExternalMissing) {
      _initializeInternalController();
    } else {
      final externalController = widget.externalController;
      if (externalController != null) {
        _configureController(externalController);
      }
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalController != null && _internalController != null) {
      _detachLoopGuard();
      _internalController?.dispose();
      _internalController = null;
    }

    if (oldWidget.externalController != widget.externalController &&
        widget.externalController != null) {
      _configureController(widget.externalController!);
    }

    if (oldWidget.videoUrl != widget.videoUrl &&
        widget.externalController == null) {
      _detachLoopGuard();
      _internalController?.dispose();
      _internalController = null;
      _initializeInternalController();
      return;
    }

    if (widget.externalController == null &&
        widget.initializeWhenExternalMissing &&
        _internalController == null) {
      _initializeInternalController();
    }
  }

  @override
  void dispose() {
    _detachLoopGuard();
    _internalController?.dispose();
    super.dispose();
  }

  void _initializeInternalController() {
    if (widget.videoUrl.startsWith('assets/')) {
      _internalController = CachedVideoPlayerPlusController.asset(
        widget.videoUrl,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    } else if (widget.videoUrl.startsWith('http://') ||
        widget.videoUrl.startsWith('https://')) {
      _internalController = CachedVideoPlayerPlusController.networkUrl(
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    } else {
      _internalController = CachedVideoPlayerPlusController.file(
        File(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    }

    final controller = _internalController!;
    controller.initialize().then((_) async {
      if (!mounted) return;
      await _configureController(controller);
      if (mounted) setState(() {});
    });
  }

  Future<void> _configureController(
    CachedVideoPlayerPlusController controller,
  ) async {
    if (!controller.value.isInitialized) return;

    await controller.setLooping(true);
    await controller.setVolume(0);
    if (widget.externalController == null) {
      _attachLoopGuard(controller);
      await controller.play();
    }
  }

  void _attachLoopGuard(CachedVideoPlayerPlusController controller) {
    if (_loopGuardController == controller) return;

    _detachLoopGuard();
    _loopGuardController = controller;
    _loopGuardListener = () {
      final value = controller.value;
      if (!value.isInitialized || value.duration == Duration.zero) return;
      if (value.isPlaying || _isRestartingLoop) return;

      final isAtEnd =
          value.position >= value.duration - const Duration(milliseconds: 120);
      if (!isAtEnd) return;

      _isRestartingLoop = true;
      controller
          .seekTo(Duration.zero)
          .then((_) => controller.play())
          .whenComplete(() => _isRestartingLoop = false);
    };
    controller.addListener(_loopGuardListener!);
  }

  void _detachLoopGuard() {
    final controller = _loopGuardController;
    final listener = _loopGuardListener;
    if (controller != null && listener != null) {
      controller.removeListener(listener);
    }
    _loopGuardController = null;
    _loopGuardListener = null;
    _isRestartingLoop = false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.externalController == null && _internalController == null) {
      return const ColoredBox(color: Colors.black);
    }

    if (!_controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: CachedVideoPlayerPlus(_controller),
        ),
      ),
    );
  }
}
