import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FireStorageService {
  static const String simulatorTestVideoPath = 'assets/video/test_video.mp4';

  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _fileExtension(String path) {
    final int dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) {
      return '.mp4';
    }
    return path.substring(dotIndex);
  }

  Future<String?> uploadProfileImage({
    required String uid,
    required File imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('user_profile').child('$uid.jpg');

      await ref.putFile(imageFile);

      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteProfileImage({required String uid}) async {
    try {
      await _storage.ref().child('user_profile').child('$uid.jpg').delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        rethrow;
      }
    }
  }

  Future<void> deleteVideoByUrl(String videoUrl) async {
    if (videoUrl.isEmpty || videoUrl.startsWith('assets/')) {
      return;
    }

    try {
      await _storage.refFromURL(videoUrl).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        rethrow;
      }
    }
  }

  Future<void> deleteVideosByUrls(Iterable<String> videoUrls) async {
    final uniqueVideoUrls = videoUrls.toSet();

    for (final videoUrl in uniqueVideoUrls) {
      await deleteVideoByUrl(videoUrl);
    }
  }

  Future<String?> getSimulatorTestVideoUrl() async {
    final ref = _storage.ref(simulatorTestVideoPath);

    try {
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        debugPrint("테스트 영상 URL 조회 에러: $e");
        return null;
      }
    }

    try {
      final byteData = await rootBundle.load(simulatorTestVideoPath);
      final snapshot = await ref.putData(
        byteData.buffer.asUint8List(),
        SettableMetadata(contentType: 'video/mp4'),
      );

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("테스트 영상 업로드 에러: $e");
      return null;
    }
  }

  Future<String?> uploadVideo(String filePath) async {
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        debugPrint("파일이 존재하지 않습니다: $filePath");
        return null;
      }

      String fileName =
          "${DateTime.now().millisecondsSinceEpoch}${_fileExtension(filePath)}";

      Reference ref = _storage.ref().child('temp_uploads').child(fileName);

      UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );

      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("FireStorageService 업로드 에러: $e");
      return null;
    }
  }
}
