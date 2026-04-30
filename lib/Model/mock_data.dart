import 'package:bababam_app/Model/post.dart';
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

final String todayDayKey = _buildDayKey(DateTime.now());

final List<Post> testPosts = [
  Post(
    id: 'p1',
    groupId: 'g1',
    authorId: 'u1',
    videoUrl: 'https://example.com/video1.mp4',
    comment: '거울1',
    createdAt: DateTime.now().copyWith(hour: 6, minute: 10),
    dayKey: todayDayKey,
    hourSlot: 6,
  ),
  Post(
    id: 'p2',
    groupId: 'g1',
    authorId: 'u1',
    videoUrl: 'https://example.com/video1.mp4',
    comment: '거울2',
    createdAt: DateTime.now().copyWith(hour: 6, minute: 10),
    dayKey: todayDayKey,
    hourSlot: 6,
  ),
  Post(
    id: 'p3',
    groupId: 'g1',
    authorId: 'u1',
    videoUrl: 'https://example.com/video1.mp4',
    comment: '거울3',
    createdAt: DateTime.now().copyWith(hour: 6, minute: 10),
    dayKey: todayDayKey,
    hourSlot: 6,
  ),
  Post(
    id: 'p4',
    groupId: 'g1',
    authorId: 'u2',
    videoUrl: 'https://example.com/video2.mp4',
    comment: '커피',
    createdAt: DateTime.now().copyWith(hour: 6, minute: 20),
    dayKey: todayDayKey,
    hourSlot: 6,
  ),
  Post(
    id: 'p5',
    groupId: 'g1',
    authorId: 'u3',
    videoUrl: 'https://example.com/video3.mp4',
    comment: '점심',
    createdAt: DateTime.now().copyWith(hour: 12, minute: 5),
    dayKey: todayDayKey,
    hourSlot: 12,
  ),
  Post(
    id: 'p6',
    groupId: 'g1',
    authorId: 'u4',
    videoUrl: 'https://example.com/video4.mp4',
    comment: '하늘',
    createdAt: DateTime.now().copyWith(hour: 18, minute: 40),
    dayKey: todayDayKey,
    hourSlot: 18,
  ),
  Post(
    id: 'p7',
    groupId: 'g2',
    authorId: 'u1',
    videoUrl: 'https://example.com/video5.mp4',
    comment: '테스트',
    createdAt: DateTime.now().copyWith(hour: 9, minute: 0),
    dayKey: todayDayKey,
    hourSlot: 9,
  ),
];

String _buildDayKey(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '${dateTime.year}-$month-$day';
}
