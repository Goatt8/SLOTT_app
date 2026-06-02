import 'package:bababam_app/Model/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String title;
  final String ownerId;
  final List<String> memberIds;
  final int memberCount;
  final List<Post>? post;

  Group({
    required this.id,
    required this.title,
    required this.memberIds,
    required this.ownerId,
    required this.memberCount,
    this.post,
  });

  int get slotCount =>
      memberCount > memberIds.length ? memberCount : memberIds.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'memberCount': memberCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Group.fromMap(String docId, Map<String, dynamic> map) {
    final memberIds = List<String>.from(map['memberIds'] ?? []);
    final memberCount =
        (map['memberCount'] as num?)?.toInt() ??
        (map['memberLimit'] as num?)?.toInt() ??
        memberIds.length;

    return Group(
      id: docId,
      title: map['title'] ?? '',
      ownerId: map['ownerId'] ?? '',
      memberIds: memberIds,
      memberCount: memberCount,
    );
  }
}
