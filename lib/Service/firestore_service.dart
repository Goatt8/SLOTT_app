import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Model/app_setting.dart';

class FireStoreService {
  FireStoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _userCollection = 'user';
  static const String _groupCollection = 'group';
  static const String _moderationReportCollection = 'moderation_reports';
  static const String _moderationBlockCollection = 'moderation_blocks';

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(_userCollection);

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection(_groupCollection);

  CollectionReference<Map<String, dynamic>> get _moderationReports =>
      _firestore.collection(_moderationReportCollection);

  CollectionReference<Map<String, dynamic>> get _moderationBlocks =>
      _firestore.collection(_moderationBlockCollection);

  // MARK: - User
  Future<void> createUser(AppUser user) async {
    await _users.doc(user.id).set(user.toMap());
  }

  Future<AppUser?> getUser(String userId) async {
    final snapshot = await _users.doc(userId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return AppUser.fromMap(snapshot.id, data);
  }

  Stream<AppUser?> watchUser(String userId) {
    return _users.doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }

      return AppUser.fromMap(snapshot.id, data);
    });
  }

  Future<List<AppUser>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) {
      return [];
    }

    final users = <AppUser>[];
    for (final userId in userIds) {
      final user = await getUser(userId);
      if (user != null) {
        users.add(user);
      }
    }
    return users;
  }

  Future<void> updateUser({
    required String userId,
    required String newName,
    String? profileUrl,
    String? fontId,
    String? colorId,
    String? hourFontId,
  }) async {
    final Map<String, dynamic> updates = {'name': newName};

    if (profileUrl != null) {
      updates['profileUrl'] = profileUrl;
    }
    if (fontId != null) {
      updates['fontId'] = fontId;
    }
    if (colorId != null) {
      updates['colorId'] = colorId;
    }
    if (hourFontId != null) {
      updates['hourFontId'] = hourFontId;
    }
    await _users.doc(userId).update(updates);
  }

  Future<void> updateUserTextStyle({
    required String userId,
    required String fontId,
    required String colorId,
    required String hourFontId,
  }) async {
    await _users.doc(userId).update({
      'fontId': fontId,
      'colorId': colorId,
      'hourFontId': hourFontId,
    });
  }

  Future<void> anonymizeDeletedUser(String userId) async {
    final expiresAt = DateTime.now().add(const Duration(days: 30));
    await _users.doc(userId).set({
      'name': '탈퇴한 사용자',
      'phoneNumber': '',
      'profileUrl': null,
      'currentPost': null,
      'blockedUserIds': <String>[],
      'termsInfo': {'hasAgreed': false, 'version': null},
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
    }, SetOptions(merge: true));
  }

  Future<void> removeUserFromAllGroups(String userId) async {
    final snapshot = await _groups
        .where('memberIds', arrayContains: userId)
        .get();

    for (final document in snapshot.docs) {
      await _firestore.runTransaction((transaction) async {
        final currentSnapshot = await transaction.get(document.reference);
        final data = currentSnapshot.data();
        if (!currentSnapshot.exists || data == null) return;

        final group = Group.fromMap(currentSnapshot.id, data);
        final remainingMemberIds = group.memberIds
            .where((memberId) => memberId != userId)
            .toList();

        if (remainingMemberIds.isEmpty) {
          transaction.delete(document.reference);
          return;
        }

        final updatedSlotOwnerIds = group.effectiveSlotOwnerIds
            .map((ownerId) => ownerId == userId ? null : ownerId)
            .toList();
        final nextOwnerId = group.ownerId == userId
            ? remainingMemberIds.first
            : group.ownerId;

        transaction.update(document.reference, {
          'memberIds': remainingMemberIds,
          'slotOwnerIds': updatedSlotOwnerIds,
          'ownerId': nextOwnerId,
        });
      });
    }
  }

  Future<void> deleteBlockedUserRecords(String userId) async {
    await _users.doc(userId).set({
      'blockedUserIds': <String>[],
    }, SetOptions(merge: true));

    final snapshot = await _users.doc(userId).collection('blocked_users').get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final document in snapshot.docs) {
      batch.delete(document.reference);
    }
    await batch.commit();
  }

  Stream<Set<String>> watchBlockedUserIds(String userId) {
    return _users.doc(userId).snapshots().map((snapshot) {
      final blockedUserIds =
          snapshot.data()?['blockedUserIds'] as List<dynamic>? ?? const [];
      return blockedUserIds.whereType<String>().toSet();
    });
  }

  Future<Set<String>> getBlockedUserIds(String userId) async {
    final userRef = _users.doc(userId);
    final userSnapshot = await userRef.get();
    final blockedUserIds =
        ((userSnapshot.data()?['blockedUserIds'] as List<dynamic>?) ?? const [])
            .whereType<String>()
            .toSet();

    // 이전 버전의 하위 컬렉션은 읽을 수 있을 때만 조용히 병합한다.
    try {
      final legacySnapshot = await userRef.collection('blocked_users').get();
      final legacyIds = legacySnapshot.docs
          .map((document) => document.id)
          .toSet();
      blockedUserIds.addAll(legacyIds);

      if (legacyIds.isNotEmpty) {
        await userRef.set({
          'blockedUserIds': FieldValue.arrayUnion(legacyIds.toList()),
        }, SetOptions(merge: true));
      }
    } on FirebaseException catch (error) {
      debugPrint('이전 차단 목록 병합 생략: ${error.code}');
    }

    return blockedUserIds;
  }

  Future<void> unblockUsers({
    required String userId,
    required Set<String> blockedUserIds,
  }) async {
    if (blockedUserIds.isEmpty) return;

    final userRef = _users.doc(userId);
    final batch = _firestore.batch();
    batch.update(userRef, {
      'blockedUserIds': FieldValue.arrayRemove(blockedUserIds.toList()),
    });
    for (final blockedUserId in blockedUserIds) {
      batch.delete(userRef.collection('blocked_users').doc(blockedUserId));
    }
    await batch.commit();
  }

  Future<void> reportPost({
    required String reporterId,
    required String reportedUserId,
    required String groupId,
    required Post post,
    required String reason,
  }) async {
    await _moderationReports.add({
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'groupId': groupId,
      'postId': post.id,
      'postPath': 'group/$groupId/posts/${post.id}',
      'videoUrl': post.videoUrl,
      'comment': post.comment,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'reviewDueAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 24)),
      ),
    });
  }

  Future<void> blockUserAndReport({
    required String reporterId,
    required String blockedUserId,
    required String groupId,
    Post? post,
    required String reason,
  }) async {
    if (reporterId == blockedUserId) {
      throw ArgumentError('자기 자신은 차단할 수 없습니다.');
    }

    final reporterRef = _users.doc(reporterId);
    await reporterRef.update({
      'blockedUserIds': FieldValue.arrayUnion([blockedUserId]),
    });

    final blockReport = {
      'reporterId': reporterId,
      'reportedUserId': blockedUserId,
      'groupId': groupId,
      'postId': post?.id,
      'postPath': post == null ? null : 'group/$groupId/posts/${post.id}',
      'videoUrl': post?.videoUrl,
      'comment': post?.comment,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'reviewDueAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 24)),
      ),
    };

    try {
      await _moderationBlocks.add(blockReport);
    } on FirebaseException catch (error) {
      debugPrint('moderation_blocks 기록 실패, reports로 대체: ${error.code}');
      await _moderationReports.add({
        ...blockReport,
        'source': 'block_and_report',
      });
    }
  }

  // MARK: - Group
  Future<void> createGroup(Group group) async {
    await _groups.doc(group.id).set(group.toMap());
  }

  Future<List<Group>> getGroupsByUser(String userId) async {
    final snapshot = await _groups
        .where('memberIds', arrayContains: userId)
        .get();

    return snapshot.docs
        .map((doc) => Group.fromMap(doc.id, doc.data()))
        .toList();
  }

  Stream<List<Group>> watchGroupsForUser(String userId) {
    return _groups.where('memberIds', arrayContains: userId).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => Group.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> joinGroup({
    required String groupId,
    required String userId,
  }) async {
    final groupRef = _groups.doc(groupId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(groupRef);
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        throw Exception('Group not found');
      }

      final group = Group.fromMap(snapshot.id, data);
      if (group.memberIds.contains(userId)) return;

      final slotOwnerIds = group.effectiveSlotOwnerIds;
      final emptySlotIndex = slotOwnerIds.indexWhere(
        (ownerId) => ownerId == null,
      );
      if (emptySlotIndex == -1) {
        throw Exception('Group is full');
      }

      slotOwnerIds[emptySlotIndex] = userId;
      transaction.update(groupRef, {
        'memberIds': FieldValue.arrayUnion([userId]),
        'slotOwnerIds': slotOwnerIds,
      });
    });
  }

  Future<void> claimGroupSlot({
    required String groupId,
    required String userId,
    required int slotIndex,
  }) async {
    final groupRef = _groups.doc(groupId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(groupRef);
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        throw Exception('Group not found');
      }

      final group = Group.fromMap(snapshot.id, data);
      final slotOwnerIds = group.effectiveSlotOwnerIds;
      if (slotIndex < 0 || slotIndex >= slotOwnerIds.length) {
        throw Exception('Invalid slot');
      }

      final currentSlotOwnerId = slotOwnerIds[slotIndex];
      if (currentSlotOwnerId != null && currentSlotOwnerId != userId) {
        throw Exception('Slot already occupied');
      }

      slotOwnerIds[slotIndex] = userId;
      transaction.update(groupRef, {
        'memberIds': FieldValue.arrayUnion([userId]),
        'slotOwnerIds': slotOwnerIds,
      });
    });
  }

  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    final groupRef = _groups.doc(groupId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(groupRef);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return;

      final group = Group.fromMap(snapshot.id, data);
      final slotOwnerIds = group.effectiveSlotOwnerIds
          .map((ownerId) => ownerId == userId ? null : ownerId)
          .toList();

      transaction.update(groupRef, {
        'memberIds': FieldValue.arrayRemove([userId]),
        'slotOwnerIds': slotOwnerIds,
      });
    });
  }

  Future<List<String>> deleteGroup(String groupId) async {
    final postsSnapshot = await _groups.doc(groupId).collection('posts').get();
    final videoUrls = await _deletePostDocuments(postsSnapshot.docs);
    await _groups.doc(groupId).delete();
    return videoUrls.toList();
  }

  // MARK: - Post
  Future<void> uploadPost(Post post) async {
    try {
      await _firestore
          .collection('group')
          .doc(post.groupId)
          .collection('posts')
          .add(post.toMap());

      debugPrint("전송 성공: 그룹 ${post.groupId}에 포스트가 추가되었습니다.");
    } catch (e) {
      debugPrint("전송 에러: $e");
      rethrow;
    }
  }

  List<Post> _parsePosts(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final posts = <Post>[];

    for (final doc in snapshot.docs) {
      try {
        final post = Post.fromMap(doc.id, doc.data());
        if (post.authorId.isEmpty || post.videoUrl.isEmpty) {
          debugPrint('포스트 데이터 누락: ${doc.reference.path}');
          continue;
        }
        posts.add(post);
      } catch (error) {
        debugPrint('포스트 파싱 실패(${doc.reference.path}): $error');
      }
    }

    return posts;
  }

  Future<List<String>> deletePostsByAuthor(String userId) async {
    final snapshot = await _firestore
        .collectionGroup('posts')
        .where('authorId', isEqualTo: userId)
        .get();

    final videoUrls = <String>{};
    WriteBatch batch = _firestore.batch();
    var operationCount = 0;

    for (final doc in snapshot.docs) {
      final videoUrl = doc.data()['videoUrl'] as String?;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        videoUrls.add(videoUrl);
      }

      batch.delete(doc.reference);
      operationCount++;

      if (operationCount == 450) {
        await batch.commit();
        batch = _firestore.batch();
        operationCount = 0;
      }
    }

    if (operationCount > 0) {
      await batch.commit();
    }

    return videoUrls.toList();
  }

  Future<Set<String>> _deletePostDocuments(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) async {
    final videoUrls = <String>{};
    WriteBatch batch = _firestore.batch();
    var operationCount = 0;

    for (final document in documents) {
      final videoUrl = document.data()['videoUrl'] as String?;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        videoUrls.add(videoUrl);
      }

      batch.delete(document.reference);
      operationCount++;

      if (operationCount == 450) {
        await batch.commit();
        batch = _firestore.batch();
        operationCount = 0;
      }
    }

    if (operationCount > 0) {
      await batch.commit();
    }

    return videoUrls;
  }

  Future<List<String>> deleteGroupPostsOlderThan({
    required String groupId,
    required Duration retention,
  }) async {
    final cutoff = DateTime.now().subtract(retention);
    final snapshot = await _groups
        .doc(groupId)
        .collection('posts')
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
        .get();

    final videoUrls = await _deletePostDocuments(snapshot.docs);
    return videoUrls.toList();
  }

  Future<bool> hasPostReferenceToVideo(String videoUrl) async {
    if (videoUrl.isEmpty) return false;

    final snapshot = await _firestore
        .collectionGroup('posts')
        .where('videoUrl', isEqualTo: videoUrl)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Stream<List<Post>> getPostsByDayStream({
    required String groupId,
    required String dayKey,
  }) {
    return _firestore
        .collection('group')
        .doc(groupId)
        .collection('posts')
        .where('dayKey', isEqualTo: dayKey)
        .snapshots()
        .map(_parsePosts);
  }

  Future<void> updatePostComment({
    required String groupId,
    required String postId,
    required String newComment,
  }) async {
    try {
      await _firestore
          .collection('group')
          .doc(groupId)
          .collection('posts')
          .doc(postId)
          .update({'comment': newComment});
      debugPrint("코멘트 수정 성공!");
    } catch (e) {
      debugPrint("코멘트 수정 에러: $e");
      rethrow;
    }
  }

  //MARK: App_Setting
  Future<AppSetting?> getAppSetting() async {
    try {
      final doc = await _firestore
          .collection('app_setting')
          .doc('terms_info')
          .get();

      if (doc.exists && doc.data() != null) {
        return AppSetting.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint("파이어스토어에서 약관 주소 로딩 실패: $e");
      return null;
    }
  }
}
