import 'package:flutter/material.dart';
import 'package:bababam_app/Model/user.dart';
import 'package:bababam_app/Model/group.dart';

final List<User> allTestUsers = [
  User(id: 'u1', name: '윤경'),
  User(id: 'u2', name: '종화'),
  User(id: 'u3', name: '민수'),
  User(id: 'u4', name: '지혜'),
  User(id: 'u5', name: '성민'),
];

final testUser1 = User(id: '', name: 'user1');
final testUser2 = User(id: '', name: 'user2');
final testUser3 = User(id: '', name: 'user3');

final List<Group> testGroups = [
  Group(id: "g1", title: 'group1', members: [testUser1, testUser2]),
  Group(id: "g1", title: 'group1', members: [testUser1, testUser3]),
];
