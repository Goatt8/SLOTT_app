import 'package:flutter/material.dart';

class Post {
  final String id;
  final String userId;
  final String imageUrl;
  final String comment;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.comment,
    required this.createdAt,
  });
}
