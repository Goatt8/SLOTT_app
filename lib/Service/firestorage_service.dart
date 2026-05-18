import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:firebase_storage/firebase_storage.dart';

class FireStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        print("파일이 존재하지 않습니다: $filePath");
        return null;
      }

      // 1. 파일명 생성 (현재 시간 기반)
      String fileName =
          "${DateTime.now().millisecondsSinceEpoch}${p.extension(filePath)}";

      // 2. 경로 설정 (나중에 유저ID 등을 인자로 받아 처리하면 더 좋습니다)
      Reference ref = _storage.ref().child('temp_uploads').child(fileName);

      // 3. 업로드
      UploadTask uploadTask = ref.putFile(file);

      // 4. 완료 후 URL 반환
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("FireStorageService 업로드 에러: $e");
      return null;
    }
  }
}
