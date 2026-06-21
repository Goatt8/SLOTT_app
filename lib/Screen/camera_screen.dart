import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bababam_app/Helper/ui_presets.dart';
import 'package:bababam_app/Screen/video_preview_screen.dart';
import 'package:bababam_app/Service/camera_availability_service.dart';
import 'package:bababam_app/Service/post_video_transform_service.dart';
import 'package:bababam_app/Widget/record_progress_ring_painter.dart';

class CameraScreen extends StatefulWidget {
  final String groupName;

  const CameraScreen({super.key, required this.groupName});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();
  final PostVideoTransformService _postVideoTransformService =
      const PostVideoTransformService();
  late AnimationController _animationController;
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isProcessingVideo = false;
  bool _isSwitchingCamera = false;
  Offset? _focusPoint;
  Offset? _exposureDragStartPoint;
  double _exposureDragStartOffset = 0;
  double _minExposureOffset = 0;
  double _maxExposureOffset = 0;
  double _currentExposureOffset = 0;
  bool _supportsExposureOffset = false;
  int _exposureRequestId = 0;
  double _minZoomLevel = 1;
  double _maxZoomLevel = 1;
  double _currentZoomLevel = 1;
  double _selectedLensFactor = 1;
  int _zoomAnimationRequestId = 0;
  Timer? _focusIndicatorTimer;

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
    if (mounted) setState(() => _isProcessingVideo = true);

    var previewPath = path;
    try {
      previewPath = await _postVideoTransformService.exportLandscapeCopy(path);
    } catch (error) {
      debugPrint('가로 프리뷰 영상 변환 실패, 원본으로 진행: $error');
    }

    if (!mounted) return;
    setState(() => _isProcessingVideo = false);
    _moveToPreviewScreen(recordedPath: previewPath);
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video == null || !mounted) return;

      await _uploadToFireStorageAndMove(video.path);
    } catch (error) {
      debugPrint('갤러리 영상 선택 실패: $error');
    }
  }

  //MARK: MoveToPreview
  void _moveToPreviewScreen({required String recordedPath}) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPreviewScreen(videoPath: recordedPath),
      ),
    );
  }

  Future<void> _recordVideo() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await _pickVideoFromGallery();
      return;
    }

    try {
      setState(() => _isRecording = true);
      _animationController.forward(from: 0.0);

      await _controller!.startVideoRecording();
      await Future.delayed(const Duration(seconds: 3));

      if (_isRecording) {
        XFile? rawVideo;
        if (_controller != null && _controller!.value.isInitialized) {
          rawVideo = await _controller!.stopVideoRecording();
        }
        _animationController.reset();
        setState(() => _isRecording = false);

        if (rawVideo == null) {
          await _pickVideoFromGallery();
          return;
        }

        await _uploadToFireStorageAndMove(rawVideo.path);
      }
    } catch (e) {
      debugPrint("4초 자동 녹화 에러: $e");
      _animationController.reset();
      setState(() => _isRecording = false);
    }
  }

  Future<void> _prepareForVideoRecording(CameraController controller) async {
    if (!controller.value.isInitialized) return;

    try {
      await controller.prepareForVideoRecording();
    } catch (e) {
      debugPrint("녹화 사전 준비 실패: $e");
    }
  }

  //MARK: Initialize
  Future<void> _initializeCamera() async {
    try {
      _cameras = await CameraAvailabilityService.cameras();

      if (_cameras != null && _cameras!.isNotEmpty) {
        await _setActiveCamera(_defaultBackCameraIndex() ?? 0);
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
        _isSwitchingCamera = false;
      });
    }
  }

  int? _findCameraIndex({
    required CameraLensDirection lensDirection,
    CameraLensType? lensType,
  }) {
    final cameras = _cameras;
    if (cameras == null) return null;

    final index = cameras.indexWhere((camera) {
      final matchesDirection = camera.lensDirection == lensDirection;
      final matchesType = lensType == null || camera.lensType == lensType;
      return matchesDirection && matchesType;
    });

    return index == -1 ? null : index;
  }

  int? _defaultBackCameraIndex() {
    return _findCameraIndex(
          lensDirection: CameraLensDirection.back,
          lensType: CameraLensType.wide,
        ) ??
        _findCameraIndex(lensDirection: CameraLensDirection.back);
  }

  int? _frontCameraIndex() {
    return _findCameraIndex(lensDirection: CameraLensDirection.front);
  }

  int? _ultraWideBackCameraIndex() {
    return _findCameraIndex(
      lensDirection: CameraLensDirection.back,
      lensType: CameraLensType.ultraWide,
    );
  }

  Future<void> _setActiveCamera(
    int cameraIndex, {
    double? initialZoomLevel,
    double? selectedLensFactor,
  }) async {
    final cameras = _cameras;
    if (cameras == null || cameras.isEmpty) return;

    final previousController = _controller;
    _focusIndicatorTimer?.cancel();
    if (mounted) {
      setState(() {
        _controller = null;
        _focusPoint = null;
        _isSwitchingCamera = true;
      });
    }

    await previousController?.dispose();

    final nextController = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.veryHigh,
    );
    await nextController.initialize();
    await nextController.lockCaptureOrientation(DeviceOrientation.portraitUp);

    var minExposureOffset = 0.0;
    var maxExposureOffset = 0.0;
    var currentExposureOffset = 0.0;
    var supportsExposureOffset = false;
    var minZoomLevel = 1.0;
    var maxZoomLevel = 1.0;
    var currentZoomLevel = 1.0;

    try {
      minExposureOffset = await nextController.getMinExposureOffset();
      maxExposureOffset = await nextController.getMaxExposureOffset();
      supportsExposureOffset = maxExposureOffset > minExposureOffset;
      currentExposureOffset = _currentExposureOffset
          .clamp(minExposureOffset, maxExposureOffset)
          .toDouble();
      if (supportsExposureOffset) {
        currentExposureOffset = await nextController.setExposureOffset(
          currentExposureOffset,
        );
      }
    } catch (e) {
      debugPrint("노출 보정 초기화 실패: $e");
    }

    try {
      minZoomLevel = await nextController.getMinZoomLevel();
      maxZoomLevel = await nextController.getMaxZoomLevel();
      currentZoomLevel = (initialZoomLevel ?? _currentZoomLevel)
          .clamp(minZoomLevel, maxZoomLevel)
          .toDouble();
      await nextController.setZoomLevel(currentZoomLevel);
    } catch (e) {
      debugPrint("줌 초기화 실패: $e");
    }

    if (!mounted) {
      await nextController.dispose();
      return;
    }

    setState(() {
      _controller = nextController;
      _selectedCameraIndex = cameraIndex;
      _isInitialized = true;
      _isSwitchingCamera = false;
      _minExposureOffset = minExposureOffset;
      _maxExposureOffset = maxExposureOffset;
      _currentExposureOffset = currentExposureOffset;
      _supportsExposureOffset = supportsExposureOffset;
      _minZoomLevel = minZoomLevel;
      _maxZoomLevel = maxZoomLevel;
      _currentZoomLevel = currentZoomLevel;
      _selectedLensFactor = selectedLensFactor ?? currentZoomLevel;
    });

    unawaited(_prepareForVideoRecording(nextController));
  }

  Future<void> _switchCamera() async {
    final cameras = _cameras;
    if (_isRecording ||
        _isSwitchingCamera ||
        cameras == null ||
        cameras.length < 2) {
      return;
    }

    HapticFeedback.lightImpact();

    final currentCamera = cameras[_selectedCameraIndex];
    final nextCameraIndex =
        currentCamera.lensDirection == CameraLensDirection.front
        ? _defaultBackCameraIndex()
        : _frontCameraIndex();

    try {
      await _setActiveCamera(nextCameraIndex ?? 0);
    } catch (e) {
      debugPrint("카메라 전환 실패: $e");
      await _recoverDefaultCamera();
      if (!mounted) return;
      setState(() => _isSwitchingCamera = false);
    }
  }

  Future<void> _selectLensFactor(double factor) async {
    final defaultBackCameraIndex = _defaultBackCameraIndex();
    final isAlreadySelectedBackLens =
        factor == _selectedLensFactor &&
        (factor == 0.5 || _selectedCameraIndex == defaultBackCameraIndex);

    if (_isRecording || _isSwitchingCamera || isAlreadySelectedBackLens) {
      return;
    }

    try {
      HapticFeedback.lightImpact();

      if (factor == 0.5) {
        final ultraWideIndex = _ultraWideBackCameraIndex();
        if (ultraWideIndex == null) return;
        await _setActiveCamera(
          ultraWideIndex,
          initialZoomLevel: 1,
          selectedLensFactor: 0.5,
        );
        return;
      }

      if (defaultBackCameraIndex == null) return;

      if (_selectedCameraIndex != defaultBackCameraIndex) {
        await _setActiveCamera(
          defaultBackCameraIndex,
          initialZoomLevel: factor,
          selectedLensFactor: factor,
        );
        return;
      }

      await _animateZoomTo(factor);
    } catch (e) {
      debugPrint("렌즈/줌 전환 실패: $e");
      await _recoverDefaultCamera();
      if (!mounted) return;
      setState(() => _isSwitchingCamera = false);
    }
  }

  Future<void> _recoverDefaultCamera() async {
    if (_controller != null) return;

    final fallbackCameraIndex = _defaultBackCameraIndex() ?? 0;
    try {
      await _setActiveCamera(
        fallbackCameraIndex,
        initialZoomLevel: 1,
        selectedLensFactor: 1,
      );
    } catch (error) {
      debugPrint("기본 카메라 복구 실패: $error");
    }
  }

  Future<void> _animateZoomTo(double targetZoomLevel) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final requestId = ++_zoomAnimationRequestId;
    final startZoomLevel = _currentZoomLevel;
    final endZoomLevel = targetZoomLevel
        .clamp(_minZoomLevel, _maxZoomLevel)
        .toDouble();

    setState(() => _selectedLensFactor = targetZoomLevel);

    const stepCount = 12;
    for (var step = 1; step <= stepCount; step++) {
      if (requestId != _zoomAnimationRequestId || !mounted) return;

      final progress = step / stepCount;
      final easedProgress = Curves.easeOutCubic.transform(progress);
      final zoomLevel =
          startZoomLevel + ((endZoomLevel - startZoomLevel) * easedProgress);

      try {
        await controller.setZoomLevel(zoomLevel);
      } catch (e) {
        debugPrint("줌 변경 실패: $e");
        return;
      }

      if (!mounted) return;
      setState(() => _currentZoomLevel = zoomLevel);
      await Future.delayed(const Duration(milliseconds: 14));
    }

    if (!mounted || requestId != _zoomAnimationRequestId) return;
    setState(() => _currentZoomLevel = endZoomLevel);
  }

  //MARK: Focus
  Future<void> _focusAt(
    Offset localOffset,
    Size previewSize, {
    bool autoDismiss = true,
  }) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final Offset relativeOffset = Offset(
        (localOffset.dx / previewSize.width).clamp(0.0, 1.0),
        (localOffset.dy / previewSize.height).clamp(0.0, 1.0),
      );

      await _controller!.setFocusPoint(relativeOffset);
      await _controller!.setExposurePoint(relativeOffset);
      if (!mounted) return;
      setState(() => _focusPoint = localOffset);
      if (autoDismiss) _scheduleFocusIndicatorDismiss();

      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint("초점 맞추기 실패: $e");
    }
  }

  void _scheduleFocusIndicatorDismiss() {
    _focusIndicatorTimer?.cancel();
    _focusIndicatorTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _focusPoint = null);
    });
  }

  void _onExposureDragStart(DragStartDetails details, Size previewSize) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _focusIndicatorTimer?.cancel();
    _exposureDragStartPoint = details.localPosition;
    _exposureDragStartOffset = _currentExposureOffset;
    _focusAt(details.localPosition, previewSize, autoDismiss: false);
  }

  void _onExposureDragUpdate(DragUpdateDetails details) {
    final startPoint = _exposureDragStartPoint;
    if (startPoint == null || !_supportsExposureOffset) return;

    final deltaY = details.localPosition.dy - startPoint.dy;
    final nextOffset = (_exposureDragStartOffset - (deltaY / 90))
        .clamp(_minExposureOffset, _maxExposureOffset)
        .toDouble();
    _setExposureOffset(nextOffset);
  }

  void _onExposureDragEnd() {
    _exposureDragStartPoint = null;
    _scheduleFocusIndicatorDismiss();
  }

  Future<void> _setExposureOffset(double offset) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final requestId = ++_exposureRequestId;
    if (mounted) {
      setState(() => _currentExposureOffset = offset);
    }

    try {
      final actualOffset = await controller.setExposureOffset(offset);
      if (!mounted || requestId != _exposureRequestId) return;
      setState(() => _currentExposureOffset = actualOffset);
    } catch (e) {
      debugPrint("노출 보정 실패: $e");
    }
  }

  Widget _landscapeIllusion(Widget child) {
    return RotatedBox(quarterTurns: 1, child: child);
  }

  //MARK: Button UI
  Widget _buildRecordButton({bool isLandscape = false}) {
    final alignment = isLandscape
        ? Alignment.centerRight
        : Alignment.bottomCenter;
    final padding = isLandscape
        ? const EdgeInsets.only(right: 42)
        : const EdgeInsets.only(bottom: 45);

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: GestureDetector(
          onTap: _isRecording
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  _recordVideo();
                },
          child: SizedBox(
            width: 80,
            height: 80,
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
                    height: 80,
                    width: 80,
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  height: _isRecording ? 25 : 55,
                  width: _isRecording ? 25 : 55,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(_isRecording ? 4 : 30),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchCameraButton({bool isLandscape = false}) {
    final canSwitch =
        (_cameras?.length ?? 0) > 1 && !_isRecording && !_isSwitchingCamera;
    final alignment = isLandscape
        ? Alignment.centerRight
        : Alignment.bottomRight;
    final padding = isLandscape
        ? const EdgeInsets.only(right: 55, top: 158)
        : const EdgeInsets.only(right: 34, bottom: 58);

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: Opacity(
          opacity: canSwitch ? 1 : 0.35,
          child: GestureDetector(
            onTap: canSwitch ? _switchCamera : null,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 1.2,
                ),
              ),
              child: _landscapeIllusion(
                const Icon(
                  Icons.cameraswitch_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLensSelector({bool isLandscape = false}) {
    final alignment = isLandscape
        ? Alignment.centerRight
        : Alignment.bottomCenter;
    final padding = isLandscape
        ? const EdgeInsets.only(right: 136)
        : const EdgeInsets.only(bottom: 144);
    final lensButtons = [
      _buildLensTextButton(
        label: '0.5',
        factor: 0.5,
        canUse: _ultraWideBackCameraIndex() != null,
      ),
      _buildLensTextButton(
        label: '1',
        factor: 1,
        canUse: _defaultBackCameraIndex() != null,
      ),
      _buildLensTextButton(
        label: '2',
        factor: 2,
        canUse: _defaultBackCameraIndex() != null,
      ),
    ];

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: isLandscape
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  lensButtons[0],
                  const SizedBox(height: 8),
                  lensButtons[1],
                  const SizedBox(height: 8),
                  lensButtons[2],
                ],
              )
            : Row(mainAxisSize: MainAxisSize.min, children: lensButtons),
      ),
    );
  }

  Widget _buildLensTextButton({
    required String label,
    required double factor,
    required bool canUse,
  }) {
    final isEnabled = canUse && !_isRecording && !_isSwitchingCamera;
    final isSelected = _selectedLensFactor == factor;

    return GestureDetector(
      onTap: isEnabled ? () => _selectLensFactor(factor) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minWidth: 42),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: _landscapeIllusion(
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: !isEnabled
                  ? Colors.white.withValues(alpha: 0.25)
                  : isSelected
                  ? Colors.orangeAccent
                  : Colors.white,
              fontSize: isSelected ? 16 : 14,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExposureIndicator() {
    final exposureRange = _maxExposureOffset - _minExposureOffset;
    final normalized = exposureRange <= 0
        ? 0.5
        : ((_currentExposureOffset - _minExposureOffset) / exposureRange)
              .clamp(0.0, 1.0)
              .toDouble();

    return Container(
      width: 34,
      height: 86,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 14),
          const SizedBox(height: 5),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Positioned(
                  bottom: normalized * 38,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //MARK: Screen UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: _isInitialized
            ? LayoutBuilder(
                builder: (context, constraints) {
                  const double previewTopPadding = 0;
                  const double previewHorizontalPadding = 0;
                  final isLandscape =
                      constraints.maxWidth > constraints.maxHeight;
                  final previewBottomPadding = isLandscape ? 0.0 : 132.0;
                  final Size previewSize = Size(
                    constraints.maxWidth - (previewHorizontalPadding * 2),
                    constraints.maxHeight -
                        previewTopPadding -
                        previewBottomPadding,
                  );
                  final cameraPreviewSize = _controller?.value.previewSize;
                  final previewChildWidth = isLandscape
                      ? cameraPreviewSize?.width ??
                            MediaQuery.of(context).size.width
                      : cameraPreviewSize?.height ??
                            MediaQuery.of(context).size.width;
                  final previewChildHeight = isLandscape
                      ? cameraPreviewSize?.height ??
                            MediaQuery.of(context).size.height
                      : cameraPreviewSize?.width ??
                            MediaQuery.of(context).size.height;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: previewTopPadding,
                            left: previewHorizontalPadding,
                            right: previewHorizontalPadding,
                          ),
                          child:
                              (_controller != null &&
                                  _controller!.value.isInitialized)
                              ? GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapUp: (details) => _focusAt(
                                    details.localPosition,
                                    previewSize,
                                  ),
                                  onPanStart: (details) => _onExposureDragStart(
                                    details,
                                    previewSize,
                                  ),
                                  onPanUpdate: _onExposureDragUpdate,
                                  onPanEnd: (_) => _onExposureDragEnd(),
                                  onPanCancel: _onExposureDragEnd,
                                  child: ClipRect(
                                    child: OverflowBox(
                                      alignment: Alignment.center,
                                      child: FittedBox(
                                        fit: isLandscape
                                            ? BoxFit.contain
                                            : BoxFit.cover,
                                        child: SizedBox(
                                          width: previewChildWidth,
                                          height: previewChildHeight,
                                          child: CameraPreview(_controller!),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFF2C2C2C),
                                  child: Center(
                                    child: _landscapeIllusion(
                                      Text(
                                        _isSwitchingCamera
                                            ? "카메라 전환 중"
                                            : "촬영 버튼을 눌러 갤러리 영상을 선택하세요",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: previewBottomPadding,
                        child: IgnorePointer(
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: 0.82),
                          ),
                        ),
                      ),
                      Positioned(
                        top: previewTopPadding,
                        left: previewHorizontalPadding,
                        right: previewHorizontalPadding,
                        bottom: previewBottomPadding,
                        child: IgnorePointer(
                          child: Center(
                            child: _landscapeIllusion(
                              Text(
                                '${DateTime.now().hour.toString().padLeft(2, '0')}:00',
                                style: AppTypography.hourOverlay(),
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
                      if (_focusPoint != null && _supportsExposureOffset)
                        Positioned(
                          left:
                              (previewHorizontalPadding + _focusPoint!.dx + 42)
                                  .clamp(12.0, constraints.maxWidth - 46)
                                  .toDouble(),
                          top: (previewTopPadding + _focusPoint!.dy - 43)
                              .clamp(12.0, constraints.maxHeight - 98)
                              .toDouble(),
                          child: _buildExposureIndicator(),
                        ),
                      Positioned(
                        top: MediaQuery.paddingOf(context).top + 10,
                        right: 20,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: _landscapeIllusion(
                              const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildLensSelector(isLandscape: isLandscape),
                      _buildRecordButton(isLandscape: isLandscape),
                      _buildSwitchCameraButton(isLandscape: isLandscape),
                      if (_isProcessingVideo)
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: 0.42),
                            child: const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
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
