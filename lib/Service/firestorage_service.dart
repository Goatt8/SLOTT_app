import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_compress/video_compress.dart';

class FireStorageService {
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

  Future<String?> uploadVideo(String filePath) async {
    MediaInfo? compressedInfo;
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        print("파일이 존재하지 않습니다: $filePath");
        return null;
      }

      // 업로드 전 압축: MediumQuality는 일반적으로 720p/중간 비트레이트로 재인코딩됩니다.
      compressedInfo = await VideoCompress.compressVideo(
        filePath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 30,
      );

      final String uploadPath = compressedInfo?.path ?? filePath;
      final File uploadFile = File(uploadPath);
      if (!uploadFile.existsSync()) {
        print("압축 결과 파일이 없어 원본으로 업로드합니다: $filePath");
      }

      // 1. 파일명 생성 (현재 시간 기반)
      String fileName =
          "${DateTime.now().millisecondsSinceEpoch}${_fileExtension(uploadPath)}";

      // 2. 경로 설정 (나중에 유저ID 등을 인자로 받아 처리하면 더 좋습니다)
      Reference ref = _storage.ref().child('temp_uploads').child(fileName);

      // 3. 업로드
      UploadTask uploadTask = ref.putFile(
        uploadFile.existsSync() ? uploadFile : file,
      );

      // 4. 완료 후 URL 반환
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("FireStorageService 업로드 에러: $e");
      return null;
    } finally {
      await VideoCompress.deleteAllCache();
    }
  }
}
