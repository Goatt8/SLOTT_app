import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:bababam_app/Helper/warning_snackbar.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();

    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.high);

      try {
        await _controller!.initialize();
        if (!mounted) return;
        setState(() {
          _isInitialized = true;
        });
      } catch (e) {}
    }
  }

  //MARK: Camera dispose
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${widget.groupName} 촬영'),
        backgroundColor: Colors.black,
      ),
      body: _isInitialized
          ? Stack(
              children: [
                Center(child: CameraPreview(_controller!)),
                _buildCaptureButton(),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  //MARK: Shutter Button
  Widget _buildCaptureButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: GestureDetector(
          onTap: _takePicture,
          child: Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: const Center(
              child: Icon(Icons.camera_alt, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      print("사진 저장 경로: ${image.path}");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진이 촬영되었습니다!')));
    } catch (e) {
      print("촬영 에러: $e");
      WarningSnackBar.showWarning(context, "촬영에 실패했습니다.");
    }
  }
}
