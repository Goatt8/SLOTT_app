import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bababam_app/Provider/post_provider.dart';

final currentUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

final blockedUserIdsProvider = StreamProvider<Set<String>>((ref) {
  final currentUserId = ref.watch(currentUserIdProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  if (currentUserId == null) {
    return Stream.value(<String>{});
  }

  return firestoreService.watchBlockedUserIds(currentUserId);
});
