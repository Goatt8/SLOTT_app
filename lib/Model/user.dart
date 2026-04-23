import 'package:flutter/material.dart';

class User {
  final String id;
  final String name;
  final String? profileImageUrl;

  User({required this.id, required this.name, this.profileImageUrl});
}
