import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bababam_app/Model/current_post_preview.dart';
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

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(_userCollection);

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection(_groupCollection);

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

  Future<void> updateUserCurrentPost({
    required String userId,
    required CurrentPostPreview? currentPost,
  }) async {
    await _users.doc(userId).update({'currentPost': currentPost?.toMap()});
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

  Future<void> clearUserCurrentPost(String userId) async {
    await updateUserCurrentPost(userId: userId, currentPost: null);
  }

  Future<void> anonymizeDeletedUser(String userId) async {
    await _users.doc(userId).set({
      'name': '탈퇴한 사용자',
      'phoneNumber': '',
      'profileUrl': null,
      'currentPost': null,
      'termsInfo': {'hasAgreed': false, 'version': null},
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // MARK: - Group
  Future<void> createGroup(Group group) async {
    await _groups.doc(group.id).set(group.toMap());
  }

  Future<Group?> getGroup(String groupId) async {
    final snapshot = await _groups.doc(groupId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return Group.fromMap(snapshot.id, data);
  }

  Future<List<Group>> getGroups() async {
    final snapshot = await _groups.get();

    return snapshot.docs
        .map((doc) => Group.fromMap(doc.id, doc.data()))
        .toList();
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

  Future<void> deleteGroup(String groupId) async {
    await _groups.doc(groupId).delete();
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

  Future<Post?> getPost({
    required String groupId,
    required String postId,
  }) async {
    final snapshot = await _firestore
        .collection('group')
        .doc(groupId)
        .collection('posts')
        .doc(postId)
        .get();

    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }
    return Post.fromMap(snapshot.id, data);
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

  Future<List<String>> getGroupPostVideoUrlsOlderThan({
    required String groupId,
    required Duration retention,
  }) async {
    final cutoff = DateTime.now().subtract(retention);
    final snapshot = await _groups
        .doc(groupId)
        .collection('posts')
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
        .get();

    final videoUrls = <String>{};
    for (final doc in snapshot.docs) {
      final videoUrl = doc.data()['videoUrl'] as String?;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        videoUrls.add(videoUrl);
      }
    }

    return videoUrls.toList();
  }

  Stream<List<Post>> getPostsByHourStream({
    required String groupId,
    required String dayKey,
    required int hourSlot,
  }) {
    return _firestore
        .collection('group')
        .doc(groupId)
        .collection('posts')
        .where('dayKey', isEqualTo: dayKey)
        .where('hourSlot', isEqualTo: hourSlot)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_parsePosts);
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
