import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bababam_app/Model/current_post_preview.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Model/user.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'User';
  static const String _groupsCollection = 'group';
  static const String _postsCollection = 'Post';

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(_usersCollection);

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection(_groupsCollection);

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection(_postsCollection);

  Future<void> createUser(User user) async {
    await _users.doc(user.id).set(user.toMap());
  }

  Future<User?> getUser(String userId) async {
    final snapshot = await _users.doc(userId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return User.fromMap(snapshot.id, data);
  }

  Future<List<User>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) {
      return [];
    }

    final users = <User>[];

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
    await _users.doc(userId).update({
      'currentPost': currentPost?.toMap(),
    });
  }

  Future<void> clearUserCurrentPost(String userId) async {
    await updateUserCurrentPost(userId: userId, currentPost: null);
  }

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

  Future<Post?> getPost(String postId) async {
    final snapshot = await _posts.doc(postId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return Post.fromMap(snapshot.id, data);
  }

  Future<List<Post>> getPostsByHour({
    required String groupId,
    required String dayKey,
    required int hourSlot,
  }) async {
    final snapshot = await _posts
        .where('groupId', isEqualTo: groupId)
        .where('dayKey', isEqualTo: dayKey)
        .where('hourSlot', isEqualTo: hourSlot)
        .orderBy('createdAt')
        .get();

    return snapshot.docs
        .map((doc) => Post.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<Post>> getPostsByDay({
    required String groupId,
    required String dayKey,
  }) async {
    final snapshot = await _posts
        .where('groupId', isEqualTo: groupId)
        .where('dayKey', isEqualTo: dayKey)
        .orderBy('hourSlot')
        .orderBy('createdAt')
        .get();

    return snapshot.docs
        .map((doc) => Post.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> deletePost(String postId) async {
    await _posts.doc(postId).delete();
  }
}
