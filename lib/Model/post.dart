import 'package:flutter/material.dart';
import 'package:bababam_app/Model/user.dart';

class Post {
  final String id;
  final String groupId;
  final String authorId;
  final String videoUrl;
  final String comment;
  final DateTime createdAt;
  final String dayKey;
  final int hourSlot;

  Post({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.videoUrl,
    required this.comment,
    required this.createdAt,
    required this.dayKey,
    required this.hourSlot,
  });
}
