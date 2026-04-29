import 'package:flutter/material.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Model/current_post_preview.dart';

class User {
  final String id;
  final String name;
  final String? profileUrl;
  final CurrentPostPreview? currentPost;

  User({
    required this.id,
    required this.name,
    this.profileUrl,
    this.currentPost,
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
