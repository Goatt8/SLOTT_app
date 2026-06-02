import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:bababam_app/Helper/ui_presets.dart';
import 'package:bababam_app/Screen/video_preview_screen.dart';
import 'package:bababam_app/Service/firestorage_service.dart';
import 'package:bababam_app/Widget/record_progress_ring_painter.dart';

class CameraScreen extends StatefulWidget {
  final String groupName;

  const CameraScreen({super.key, required this.groupName});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  final FireStorageService _storageService = FireStorageService();
  late AnimationController _animationController;
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isRecordTapped = false;
  Offset? _focusPoint;
  Timer? _focusIndicatorTimer;

  String testVideoPath = 'assets/video/test_video.mp4';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _focusIndicatorTimer?.cancel();
    _controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _uploadToFireStorageAndMove(String path) async {
    final uploadFuture = _storageService.uploadVideo(path);
    _moveToPreviewScreen(
      recordedPath: path,
      uploadedVideoUrlFuture: uploadFuture,
    );
  }

  //MARK: MoveToPreview
  void _moveToPreviewScreen({
    required String recordedPath,
    Future<String?>? uploadedVideoUrlFuture,
  }) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPreviewScreen(
          videoPath: recordedPath,
          uploadedVideoUrlFuture: uploadedVideoUrlFuture,
        ),
      ),
    );
  }

  Future<void> _recordVideo() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint("컨트롤러가 없으므로 테스트 영상으로 즉시 이동합니다.");
      _moveToPreviewScreen(recordedPath: 'assets/video/test_video.mp4');
      return;
    }

    try {
      setState(() => _isRecordTapped = true);
      Future.delayed(const Duration(milliseconds: 140), () {
        if (!mounted) return;
        setState(() => _isRecordTapped = false);
      });

      await _controller!.startVideoRecording();
      setState(() => _isRecording = true);

      _animationController.forward(from: 0.0);
      await Future.delayed(const Duration(seconds: 3));

      if (_isRecording) {
        XFile? rawVideo;
        if (_controller != null && _controller!.value.isInitialized) {
          rawVideo = await _controller!.stopVideoRecording();
        }
        _animationController.reset();
        setState(() => _isRecording = false);

        final String finalPath = rawVideo?.path ?? testVideoPath;

        _uploadToFireStorageAndMove(finalPath);
      }
    } catch (e) {
      debugPrint("4초 자동 녹화 에러: $e");
      _animationController.reset();
      setState(() => _isRecording = false);
    }
  }

  //MARK: Initialize
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(_cameras![0], ResolutionPreset.veryHigh);
        await _controller!.initialize();
        await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

        if (!mounted) return;
        setState(() {
          _isInitialized = true;
        });
      } else {
        debugPrint("카메라 리스트가 비어있음 -> UI 점검을 위해 화면 유지");
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("카메라 초기화 예외 발생 -> UI 점검을 위해 화면 유지: $e");
      setState(() {
        _isInitialized = true;
      });
    }
  }

  //MARK: Focus
  Future<void> _onTapToFocus(TapUpDetails details, Size previewSize) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final Offset localOffset = details.localPosition;
      final Offset relativeOffset = Offset(
        (localOffset.dx / previewSize.width).clamp(0.0, 1.0),
        (localOffset.dy / previewSize.height).clamp(0.0, 1.0),
      );

      await _controller!.setFocusPoint(relativeOffset);
      await _controller!.setExposurePoint(relativeOffset);
      if (!mounted) return;
      setState(() => _focusPoint = localOffset);
      _focusIndicatorTimer?.cancel();
      _focusIndicatorTimer = Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() => _focusPoint = null);
      });

      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint("초점 맞추기 실패: $e");
    }
  }

  //MARK: Button UI
  Widget _buildRecordButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: GestureDetector(
          onTap: _isRecording
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  _recordVideo();
                },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 4,
                  ),
                ),
              ),

              if (_isRecording)
                SizedBox(
                  height: 90,
                  width: 90,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: RecordProgressRingPainter(
                          progress: _animationController.value,
                        ),
                      );
                    },
                  ),
                ),
              AnimatedScale(
                scale: _isRecordTapped ? 0.9 : 1.0,
                duration: const Duration(milliseconds: 120),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: _isRecording ? 25 : 55,
                  width: _isRecording ? 25 : 55,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(_isRecording ? 4 : 30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //MARK: Screen UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isInitialized
            ? LayoutBuilder(
                builder: (context, constraints) {
                  const double previewTopPadding = 26;
                  const double previewBottomPadding = 132;
                  const double previewHorizontalPadding = 14;
                  final Size previewSize = Size(
                    constraints.maxWidth - (previewHorizontalPadding * 2),
                    constraints.maxHeight -
                        (previewTopPadding + previewBottomPadding),
                  );
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: previewTopPadding,
                            bottom: previewBottomPadding,
                            left: previewHorizontalPadding,
                            right: previewHorizontalPadding,
                          ),
                          child:
                              (_controller != null &&
                                  _controller!.value.isInitialized)
                              ? GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapUp: (details) =>
                                      _onTapToFocus(details, previewSize),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(26),
                                    child: ClipRect(
                                      child: OverflowBox(
                                        alignment: Alignment.center,
                                        child: FittedBox(
                                          fit: BoxFit.cover,
                                          child: SizedBox(
                                            width:
                                                _controller
                                                    ?.value
                                                    .previewSize
                                                    ?.height ??
                                                MediaQuery.of(
                                                  context,
                                                ).size.width,
                                            height:
                                                _controller
                                                    ?.value
                                                    .previewSize
                                                    ?.width ??
                                                MediaQuery.of(
                                                  context,
                                                ).size.height,
                                            child: CameraPreview(_controller!),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFF2C2C2C),
                                  child: const Center(
                                    child: Text(
                                      "시뮬레이터: 카메라 없음",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: previewTopPadding,
                            bottom: previewBottomPadding,
                            left: previewHorizontalPadding,
                            right: previewHorizontalPadding,
                          ),
                          child: IgnorePointer(
                            child: Center(
                              child: AspectRatio(
                                aspectRatio:
                                    AppLayoutPolicy.previewVideoAspectRatio,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 1.4,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_focusPoint != null)
                        Positioned(
                          left: previewHorizontalPadding + _focusPoint!.dx - 30,
                          top: previewTopPadding + _focusPoint!.dy - 30,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1.3, end: 1.0),
                            duration: const Duration(milliseconds: 260),
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.2,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 10,
                        right: 20,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      _buildRecordButton(),
                    ],
                  );
                },
              )
            : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
      ),
    );
  }
}
