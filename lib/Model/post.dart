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
  final int slotIndex;

  Post({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.videoUrl,
    required this.comment,
    required this.createdAt,
    required this.dayKey,
    required this.hourSlot,
    required this.slotIndex,
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
      'slotIndex': slotIndex,
    };
  }

  factory Post.fromMap(String id, Map<String, dynamic> map) {
    final createdAtValue = map['createdAt'];
    final createdAt = createdAtValue is Timestamp
        ? createdAtValue.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);

    return Post(
      id: id,
      authorId: map['authorId'] as String? ?? '',
      groupId: map['groupId'] as String? ?? '',
      videoUrl: map['videoUrl'] as String? ?? '',
      comment: map['comment'] as String? ?? '',
      createdAt: createdAt,
      dayKey: map['dayKey'] as String? ?? _dayKeyFrom(createdAt),
      hourSlot: (map['hourSlot'] as num?)?.toInt() ?? createdAt.hour,
      slotIndex: (map['slotIndex'] as num?)?.toInt() ?? -1,
    );
  }

  static String _dayKeyFrom(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
}
