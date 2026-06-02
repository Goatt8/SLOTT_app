import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  User? get currentUser => _auth.currentUser;
  String? _verificationId;
  String? _reauthVerificationId;

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

  Future<void> sendReauthCode(Function(String) onCodeSent) async {
    final phoneNumber = currentUser?.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw Exception("재인증할 전화번호가 없습니다.");
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await currentUser?.reauthenticateWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint("재인증 실패: ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        _reauthVerificationId = verificationId;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _reauthVerificationId = verificationId;
      },
    );
  }

  Future<void> reauthenticateWithCode(String smsCode) async {
    if (_reauthVerificationId == null) {
      throw Exception("재인증 정보가 없습니다.");
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _reauthVerificationId!,
      smsCode: smsCode,
    );

    final user = currentUser;
    if (user == null) {
      throw Exception("로그인된 인증 정보가 없습니다.");
    }

    await user.reauthenticateWithCredential(credential);
  }

  //MARK: CurrentUser Check
  Future<Map<String, dynamic>?> checkCurrentUserStatus() async {
    User? user = currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _db
          .collection('user')
          .doc(user.uid)
          .get();
      return {"user": user, "isExistingUser": userDoc.exists};
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

  //MARK: Delete Account
  Future<void> deleteAccount() async {
    try {
      User? user = currentUser;
      if (user != null) {
        await user.delete();
      } else {
        throw Exception("로그인된 인증 정보가 없습니다.");
      }
    } catch (e) {
      print("Firebase Auth 계정 삭제 오류: $e");
      rethrow;
    }
  }
}
