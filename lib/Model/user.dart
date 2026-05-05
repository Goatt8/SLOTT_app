import 'package:bababam_app/Model/current_post_preview.dart';

class User {
  final String id;
  final String name;
  final String phoneNumber;
  final String? profileUrl;
  final CurrentPostPreview? currentPost;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.profileUrl,
    this.currentPost,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'profileUrl': profileUrl,
      'currentPost': currentPost?.toMap(),
    };
  }

  factory User.fromMap(String id, Map<String, dynamic> map) {
    return User(
      id: id,
      name: map['name'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      profileUrl: map['profileUrl'] as String?,
      currentPost: map['currentPost'] != null
          ? CurrentPostPreview.fromMap(
              map['currentPost'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  bool get shouldShowUploadForm {
    if (currentPost == null) return true;

    final now = DateTime.now();
    final lastTime = currentPost!.createdAt;

    return now.year != lastTime.year ||
        now.month != lastTime.month ||
        now.day != lastTime.day ||
        now.hour != lastTime.hour;
  }
}
