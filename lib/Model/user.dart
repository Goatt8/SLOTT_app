import 'package:flutter/material.dart';
import 'package:bababam_app/Model/post.dart';

class User {
  final String id;
  final String name;
  final String? profileImageUrl;
  final Post? currentPost;
  final List<Post> history;

  User({
    required this.id,
    required this.name,
    this.profileImageUrl,
    this.currentPost,
    this.history = const [],
  });

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
