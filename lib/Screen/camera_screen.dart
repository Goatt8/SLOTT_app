import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:bababam_app/Helper/warning_snackbar.dart';
import 'package:bababam_app/Screen/video_preview_screen.dart';

class CameraScreen extends StatefulWidget {
  final String groupName;

  const CameraScreen({super.key, required this.groupName});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;

  String testVideoPath = 'assets/video/test_video.mp4';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _recordVideo() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print("컨트롤러가 없으므로 테스트 영상으로 즉시 이동합니다.");
      _moveToPreviewScreen('assets/video/test_video.mp4');
      return;
    }

    try {
      await _controller!.startVideoRecording();
      setState(() => _isRecording = true);

      await Future.delayed(const Duration(seconds: 3));

      if (_isRecording) {
        final file = await _controller!.stopVideoRecording();
        setState(() => _isRecording = false);

        //MARK: test
        _moveToPreviewScreen(testVideoPath);
        //  _moveToPreviewScreen(file.path);
      }
    } catch (e) {
      print("4초 자동 녹화 에러: $e");
      setState(() => _isRecording = false);
    }
  }

  //MARK: Initialize
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(_cameras![0], ResolutionPreset.medium);
        await _controller!.initialize();

        if (!mounted) return;
        setState(() {
          _isInitialized = true;
        });
      } else {
        print("카메라 리스트가 비어있음");
        //MARK: test
        // _moveToPreviewScreen(testVideoPath);

        print("카메라 리스트가 비어있음 -> UI 점검을 위해 화면 유지");
        setState(() {
          _isInitialized = true; //MARK: test목적으로 true설정
        });
      }
    } catch (e) {
      print("카메라 초기화 중 예외 발생 (시뮬레이터 예상): $e");
      //MARK: test
      // _moveToPreviewScreen(testVideoPath);

      print("카메라 초기화 예외 발생 -> UI 점검을 위해 화면 유지: $e");
      setState(() {
        _isInitialized = true;
      });
    }
  }

  //MARK: MoveToPreview
  void _moveToPreviewScreen(String recordedPath) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPreviewScreen(videoPath: recordedPath),
      ),
    );
  }

  //MARK: Button UI
  Widget _buildRecordButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: GestureDetector(
          onTap: _recordVideo,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _isRecording ? 30 : 60,
                width: _isRecording ? 30 : 60,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(_isRecording ? 5 : 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized
          ? Stack(
              children: [
                Positioned.fill(
                  child:
                      (_controller != null && _controller!.value.isInitialized)
                      ? ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _controller!.value.previewSize!.height,
                                height: _controller!.value.previewSize!.width,
                                child: CameraPreview(_controller!),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color.fromARGB(255, 208, 146, 146),
                          child: const Center(
                            child: Text(
                              "시뮬레이터: 카메라 없음",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                ),
                _buildRecordButton(),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
