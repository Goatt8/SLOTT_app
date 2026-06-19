import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:bababam_app/Model/post_video_file.dart';

class UploadedPostVideo {
  const UploadedPostVideo({required this.url, required this.storagePath});

  final String url;
  final String storagePath;
}

class FireStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String groupPostVideosRoot = 'group_post_videos';

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

  String buildPostVideoStoragePath({
    required String groupId,
    required String postId,
    required String filePath,
  }) {
    return '$groupPostVideosRoot/$groupId/$postId${_fileExtension(filePath)}';
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

  Future<void> deleteVideo({String? videoUrl, String? storagePath}) async {
    if ((videoUrl == null ||
            videoUrl.isEmpty ||
            videoUrl.startsWith('assets/')) &&
        (storagePath == null || storagePath.isEmpty)) {
      return;
    }

    try {
      final ref = storagePath != null && storagePath.isNotEmpty
          ? _storage.ref(storagePath)
          : _storage.refFromURL(videoUrl!);
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        return;
      }

      if (!ref.fullPath.startsWith('$groupPostVideosRoot/') &&
          !_isOwnedTempUpload(ref, currentUserId)) {
        return;
      }

      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        rethrow;
      }
    }
  }

  Future<void> deleteVideoByUrl(String videoUrl) async {
    await deleteVideo(videoUrl: videoUrl);
  }

  Future<void> deletePostVideoFiles(Iterable<PostVideoFile> videoFiles) async {
    final uniqueVideoFiles = <String, PostVideoFile>{};

    for (final videoFile in videoFiles) {
      if (!videoFile.hasReference) continue;
      final key = videoFile.storagePath?.isNotEmpty == true
          ? videoFile.storagePath!
          : videoFile.videoUrl!;
      uniqueVideoFiles[key] = videoFile;
    }

    for (final videoFile in uniqueVideoFiles.values) {
      await deleteVideo(
        videoUrl: videoFile.videoUrl,
        storagePath: videoFile.storagePath,
      );
    }
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

  Future<UploadedPostVideo?> uploadPostVideo({
    required String filePath,
    required String groupId,
    required String postId,
  }) async {
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        debugPrint("파일이 존재하지 않습니다: $filePath");
        return null;
      }

      final storagePath = buildPostVideoStoragePath(
        groupId: groupId,
        postId: postId,
        filePath: filePath,
      );
      final ref = _storage.ref(storagePath);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      return UploadedPostVideo(url: url, storagePath: storagePath);
    } catch (e) {
      debugPrint("Post 영상 업로드 에러: $e");
      return null;
    }
  }
}
