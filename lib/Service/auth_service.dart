import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _verificationId;

  //MARK: Send Code
  Future<void> sendCode(String phoneNumber, Function(String) onCodeSent) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print("인증 실패: ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // MARK: Verify Code
  Future<Map<String, dynamic>?> verifyCode(String smsCode) async {
    if (_verificationId == null) return null;

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _db
            .collection('user')
            .doc(user.uid)
            .get();

        return {"user": user, "isExistingUser": userDoc.exists};
      }
    } catch (e) {
      print("인증 또는 Firestore 조회 오류: $e");
    }
    return null;
  }

  //Mark: Logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("로그아웃 오류: $e");
      rethrow;
    }
  }
}
