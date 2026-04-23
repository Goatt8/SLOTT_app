import 'package:flutter/material.dart';
import 'package:bababam_app/Model/user.dart';

class Post {
  final String id;
  final User author;
  final String imageUrl;
  final String comment;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.author,
    required this.imageUrl,
    required this.comment,
    required this.createdAt,
  });
}
