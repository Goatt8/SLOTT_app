import 'package:bababam_app/Model/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String title;
  final String ownerId;
  final List<String> memberIds;
  final List<Post>? post;

  Group({
    required this.id,
    required this.title,
    required this.memberIds,
    required this.ownerId,
    this.post,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Group.fromMap(String docId, Map<String, dynamic> map) {
    return Group(
      id: docId,
      title: map['title'] ?? '',
      ownerId: map['ownerId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
    );
  }
}
