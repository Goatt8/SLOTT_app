import 'package:bababam_app/Model/current_post_preview.dart';

class User {
  final String id;
  final String name;
  final String? profileUrl;
  final String phoneNumber; // 추가: 인증된 휴대폰 번호
  final DateTime createdAt; // 추가: 가입일 (관리용)
  final CurrentPostPreview? currentPost;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.createdAt,
    this.profileUrl,
    this.currentPost,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'profileUrl': profileUrl,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'currentPost': currentPost?.toMap(),
    };
  }

  factory User.fromMap(String id, Map<String, dynamic> map) {
    return User(
      id: id,
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
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
