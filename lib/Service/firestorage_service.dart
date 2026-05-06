import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FireStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfileImage({
    required String uid,
    required File imageFile,
  }) async {
    try {
      // 1. 저장 경로 설정 (user_profile/UID.jpg)
      final ref = _storage.ref().child('user_profile').child('$uid.jpg');

      // 2. 파일 업로드
      await ref.putFile(imageFile);

      // 3. 업로드된 파일의 URL 가져오기
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      // 에러 처리 (필요에 따라 print 혹은 log)
      return null;
    }
  }
}
