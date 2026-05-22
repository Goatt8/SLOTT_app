import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final CachedVideoPlayerPlusController? externalController;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.externalController,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  CachedVideoPlayerPlusController? _internalController;
  CachedVideoPlayerPlusController get _controller =>
      widget.externalController ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.externalController == null) {
      _initializeInternalController();
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalController != null && _internalController != null) {
      _internalController?.dispose();
      _internalController = null;
    }

    if (oldWidget.videoUrl != widget.videoUrl &&
        widget.externalController == null) {
      _internalController?.dispose();
      _internalController = null;
      _initializeInternalController();
      return;
    }

    if (widget.externalController == null && _internalController == null) {
      _initializeInternalController();
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  void _initializeInternalController() {
    if (widget.videoUrl.startsWith('assets/')) {
      _internalController = CachedVideoPlayerPlusController.asset(
        widget.videoUrl,
      );
    } else if (widget.videoUrl.startsWith('http://') ||
        widget.videoUrl.startsWith('https://')) {
      _internalController = CachedVideoPlayerPlusController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
    } else {
      _internalController = CachedVideoPlayerPlusController.file(
        File(widget.videoUrl),
      );
    }

    _internalController!.initialize().then((_) {
      if (mounted) {
        _controller.setLooping(true);
        _controller.play();
        _controller.setVolume(0);
        setState(() {});
      }
    });
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
