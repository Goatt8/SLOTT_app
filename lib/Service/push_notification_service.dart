import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _registeredUserId;

  Future<void> configureForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('푸시 알림 권한이 거부되었습니다.');
      return;
    }

    await _messaging.setAutoInitEnabled(true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await _saveCurrentToken(user.uid);
    _listenForTokenRefresh(user.uid);
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _registeredUserId = null;
  }

  Future<void> _saveCurrentToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM 토큰을 아직 발급받지 못했습니다.');
        return;
      }

      await _saveToken(userId: userId, token: token);
    } catch (error) {
      debugPrint('FCM 토큰 저장 실패: $error');
    }
  }

  void _listenForTokenRefresh(String userId) {
    if (_registeredUserId == userId && _tokenRefreshSubscription != null) {
      return;
    }

    unawaited(_tokenRefreshSubscription?.cancel());
    _registeredUserId = userId;
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      unawaited(_saveToken(userId: userId, token: token));
    });
  }

  Future<void> _saveToken({
    required String userId,
    required String token,
  }) async {
    await _firestore
        .collection('user')
        .doc(userId)
        .collection('fcmTokens')
        .doc(token)
        .set({
          'token': token,
          'platform': _platform,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    return 'unknown';
  }
}
