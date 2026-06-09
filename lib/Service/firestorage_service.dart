import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FireStorageService {
  static const String simulatorTestAssetVideoPath =
      'assets/video/test_video.mp4';
  static const List<String> simulatorTestStorageVideoPaths = [
    'assets/video/test_video.mp4',
  ];

  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isOwnedTempUpload(Reference ref, String userId) {
    final pathSegments = ref.fullPath.split('/');
    return pathSegments.length >= 3 &&
        pathSegments.first == 'temp_uploads' &&
        pathSegments[1] == userId;
  }

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
      final ref = _storage.refFromURL(videoUrl);
      if (simulatorTestStorageVideoPaths.contains(ref.fullPath)) {
        return;
      }

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null || !_isOwnedTempUpload(ref, currentUserId)) {
        return;
      }

      await ref.delete();
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
    for (final path in simulatorTestStorageVideoPaths) {
      try {
        return await _storage.ref(path).getDownloadURL();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') {
          debugPrint("테스트 영상 URL 조회 에러($path): $e");
          return null;
        }
      }
    }

    debugPrint("테스트 영상이 Storage에 없습니다: $simulatorTestStorageVideoPaths");
    return null;
  }

  Future<String?> uploadVideo(String filePath) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        debugPrint("로그인된 사용자만 영상을 업로드할 수 있습니다.");
        return null;
      }

      File file = File(filePath);
      if (!file.existsSync()) {
        debugPrint("파일이 존재하지 않습니다: $filePath");
        return null;
      }

      String fileName =
          "${DateTime.now().millisecondsSinceEpoch}${_fileExtension(filePath)}";

      Reference ref = _storage
          .ref()
          .child('temp_uploads')
          .child(currentUserId)
          .child(fileName);

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
