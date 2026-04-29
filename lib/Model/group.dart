import 'package:bababam_app/Model/post.dart';

class Group {
  final String id;
  final String title;
  final List<String> memberIds;
  final List<Post>? post;

  Group({
    required this.id,
    required this.title,
    required this.memberIds,
    this.post,
  });

  Map<String, dynamic> toMap() {
    return {'title': title, 'memberIds': memberIds};
  }

  factory Group.fromMap(String id, Map<String, dynamic> map) {
    return Group(
      id: id,
      title: map['title'] as String? ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? const []),
    );
  }
}
