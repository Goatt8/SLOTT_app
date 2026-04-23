import 'package:flutter/material.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Model/user.dart';

class Group {
  final String id;
  final String title;
  final List<User> members;
  final List<Post>? post;

  Group({
    required this.id,
    required this.title,
    required this.members,
    this.post,
  });
}
