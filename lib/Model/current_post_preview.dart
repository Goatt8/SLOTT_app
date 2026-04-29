import 'package:cloud_firestore/cloud_firestore.dart';

class CurrentPostPreview {
  final String postId;
  final String videoUrl;
  final DateTime createdAt;

  const CurrentPostPreview({
    required this.postId,
    required this.videoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'videoUrl': videoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CurrentPostPreview.fromMap(Map<String, dynamic> map) {
    return CurrentPostPreview(
      postId: map['postId'] as String,
      videoUrl: map['videoUrl'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
