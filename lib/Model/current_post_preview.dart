import 'package:flutter/material.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Model/user.dart';

class CurrentPostPreview {
  final String postId;
  final String videoUrl;
  final DateTime createdAt;

  const CurrentPostPreview({
    required this.postId,
    required this.videoUrl,
    required this.createdAt,
  });
}
