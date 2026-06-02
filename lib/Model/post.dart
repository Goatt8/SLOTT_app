import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String groupId;
  final String authorId;
  final String videoUrl;
  final String comment;
  final DateTime createdAt;
  final String dayKey;
  final int hourSlot;

  Post({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.videoUrl,
    required this.comment,
    required this.createdAt,
    required this.dayKey,
    required this.hourSlot,
  });

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'groupId': groupId,
      'videoUrl': videoUrl,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'dayKey': dayKey,
      'hourSlot': hourSlot,
    };
  }

  factory Post.fromMap(String id, Map<String, dynamic> map) {
    return Post(
      id: id,
      authorId: map['authorId'] as String,
      groupId: map['groupId'] as String,
      videoUrl: map['videoUrl'] as String,
      comment: map['comment'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      dayKey: map['dayKey'] as String,
      hourSlot: map['hourSlot'] as int,
    );
  }
}
