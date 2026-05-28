import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bababam_app/Model/current_post_preview.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Model/app_user.dart';

class FireStoreService {
  FireStoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _userCollection = 'user';
  static const String _groupCollection = 'group';
  static const String _postCollection = 'post';

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(_userCollection);

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection(_groupCollection);

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection(_postCollection);

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
  }) async {
    final Map<String, dynamic> updates = {'name': newName};

    if (profileUrl != null) {
      updates['profileUrl'] = profileUrl;
    }
    await _users.doc(userId).update(updates);
  }

  Future<void> clearUserCurrentPost(String userId) async {
    await updateUserCurrentPost(userId: userId, currentPost: null);
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
    final snapshot = await groupRef.get();

    if (!snapshot.exists) {
      throw Exception('Group not found');
    }

    await groupRef.update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    await _groups.doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> deleteGroup(String groupId) async {
    await _groups.doc(groupId).delete();
  }

  // MARK: - Post
  Future<void> createPost(Post post) async {
    final postRef = _posts.doc(post.id);
    final userRef = _users.doc(post.authorId);

    final batch = _firestore.batch();

    batch.set(postRef, post.toMap());
    batch.update(userRef, {
      'currentPost': CurrentPostPreview(
        postId: post.id,
        videoUrl: post.videoUrl,
        createdAt: post.createdAt,
      ).toMap(),
    });

    await batch.commit();
  }

  Future<void> uploadPost(Post post) async {
    try {
      await _firestore
          .collection('group')
          .doc(post.groupId)
          .collection('posts')
          .add(post.toMap());

      print("전송 성공: 그룹 ${post.groupId}에 포스트가 추가되었습니다.");
    } catch (e) {
      print("전송 에러: $e");
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
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Post.fromMap(doc.id, doc.data()))
              .toList(),
        );
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
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Post.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
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
          .update({
            'comment': newComment, // Firestore 문서의 comment 필드만 덮어씌움
          });
      print("코멘트 수정 성공!");
    } catch (e) {
      print("코멘트 수정 에러: $e");
      rethrow;
    }
  }

  Future<void> deletePost({
    required String groupId,
    required String postId,
  }) async {
    await _firestore
        .collection('group')
        .doc(groupId)
        .collection('posts')
        .doc(postId)
        .delete();
  }
}
