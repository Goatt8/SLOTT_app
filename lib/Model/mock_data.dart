import 'package:bababam_app/Model/user.dart';
import 'package:bababam_app/Model/group.dart';

final List<User> allTestUsers = [
  User(id: 'u1', name: '윤경'),
  User(id: 'u2', name: '종화'),
  User(id: 'u3', name: '민수'),
  User(id: 'u4', name: '지혜'),
  User(id: 'u5', name: '성민'),
];

final testUser1 = User(id: '12', name: 'user1');
final testUser2 = User(id: '43', name: 'user2');
final testUser3 = User(id: '42', name: 'user3');
final testUser4 = User(id: '13', name: 'user4');
final testUser5 = User(id: '41', name: 'user5');

final List<Group> testGroups = [
  Group(id: 'g1', title: 'group1', memberIds: ['u1', 'u2', 'u3', 'u4']),
  Group(id: 'g2', title: 'group2', memberIds: ['u1', 'u3']),
];
