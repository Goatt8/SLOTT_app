import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraAvailabilityService {
  CameraAvailabilityService._();

  static Future<List<CameraDescription>>? _camerasFuture;

  static void preload() {
    _camerasFuture ??= _loadCameras();
  }

  static Future<List<CameraDescription>> cameras() {
    return _camerasFuture ??= _loadCameras();
  }

  static Future<List<CameraDescription>> _loadCameras() async {
    try {
      return await availableCameras();
    } catch (error) {
      debugPrint('카메라 목록 사전 로드 실패: $error');
      _camerasFuture = null;
      rethrow;
    }
  }
}
