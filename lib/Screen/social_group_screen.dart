import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Service/firestore_service.dart';
import 'package:bababam_app/Widget/member_post_card.dart';
import 'package:bababam_app/Widget/navigation_triangle_button.dart';

class SocialGroupScreen extends StatefulWidget {
  final Group group;
  final String groupId;

  const SocialGroupScreen({
    super.key,
    required this.group,
    required this.groupId,
  });

  @override
  State<SocialGroupScreen> createState() => _SocialGroupScreenState();
}

class _SocialGroupScreenState extends State<SocialGroupScreen> {
  final FireStoreService _firestoreService = FireStoreService();

  int _currentPage = 0;
  late Stream<List<Post>> _postsStream;
  late Future<List<AppUser>> _membersFuture;
  late int _currentHour;
  late String _todayKey;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _initData();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      if (now.hour != _currentHour) {
        setState(() {
          _updateTime();
          _initData();
        });
      }
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    _currentHour = now.hour;
    _todayKey = _generateDayKey(now);
  }

  //MARK: Data Stream - init
  void _initData() {
    _membersFuture = _firestoreService.getUsersByIds(widget.group.memberIds);
    _postsStream = _firestoreService.getPostsByDayStream(
      groupId: widget.groupId,
      dayKey: _todayKey,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SocialGroupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.group.id != widget.group.id) {
      setState(() {
        _currentPage = 0;
        _updateTime();
        _membersFuture = _firestoreService.getUsersByIds(
          widget.group.memberIds,
        );
        _postsStream = _firestoreService.getPostsByDayStream(
          groupId: widget.groupId,
          dayKey: _todayKey,
        );
      });
    }
  }

  String _generateDayKey(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  Widget _buildGroupContent(List<AppUser> members, List<Post> groupPosts) {
    final List<int> availableHours =
        groupPosts.map((post) => post.hourSlot).toSet().toList()..sort();
    final int currentPage = _resolveCurrentPage(availableHours);

    if (availableHours.isEmpty) {
      return _buildMembersWithoutPosts(members);
    }

    final int selectedHour = availableHours[currentPage];
    final List<Post> selectedPosts = groupPosts
        .where((post) => post.hourSlot == selectedHour)
        .toList();
    final int count = members.length;

    return Column(
      children: [
        _buildDotIndicator(
          availableHours: availableHours,
          currentIndex: currentPage,
          groupPosts: groupPosts,
          memberCount: members.length,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: count <= 6
                ? _buildVerticalLayout(members, selectedPosts, selectedHour)
                : _buildGridLayout(members, selectedPosts, selectedHour),
          ),
        ),
      ],
    );
  }

  int _resolveCurrentPage(List<int> availableHours) {
    if (availableHours.isEmpty) {
      _currentPage = 0;
      return 0;
    }

    if (_currentPage >= availableHours.length) {
      _currentPage = 0;
    }

    return _currentPage;
  }

  Post? _findPostForUser(List<Post> posts, String userId) {
    for (final post in posts) {
      if (post.authorId == userId) {
        return post;
      }
    }
    return null;
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        '아직 올라온 시간대가 없어요',
        style: TextStyle(color: Colors.white54, fontSize: 13),
      ),
    );
  }

  Widget _buildMembersWithoutPosts(List<AppUser> members) {
    if (members.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: members
          .map(
            (user) => Expanded(
              child: MemberPostCard(member: user, post: null, hourSlot: 0),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDotIndicator({
    required List<int> availableHours,
    required int currentIndex,
    required List<Post> groupPosts,
    required int memberCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          NavigationTriangleButton(
            isLeft: true,
            enabled: currentIndex > 0,
            onTap: currentIndex > 0
                ? () {
                    setState(() {
                      _currentPage -= 1;
                    });
                  }
                : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(availableHours.length, (index) {
                final hour = availableHours[index];
                final int postCount = groupPosts
                    .where((post) => post.hourSlot == hour)
                    .length;
                final bool isComplete = postCount == memberCount;
                final bool isSelected = index == currentIndex;

                final Color indicatorColor;
                if (isSelected && isComplete) {
                  indicatorColor = const Color(0xFF7C3AED);
                } else if (isSelected) {
                  indicatorColor = Colors.white;
                } else if (isComplete) {
                  indicatorColor = const Color(0xFF7C3AED);
                } else {
                  indicatorColor = Colors.white24;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isSelected ? 16 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                    ),
                  ),
                );
              }),
            ),
          ),
          NavigationTriangleButton(
            isLeft: false,
            enabled: currentIndex < availableHours.length - 1,
            onTap: currentIndex < availableHours.length - 1
                ? () {
                    setState(() {
                      _currentPage += 1;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalLayout(
    List<AppUser> members,
    List<Post> selectedPosts,
    int selectedHour,
  ) {
    return Column(
      children: members
          .map(
            (user) => Expanded(
              child: MemberPostCard(
                member: user,
                post: _findPostForUser(selectedPosts, user.id),
                hourSlot: selectedHour,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGridLayout(
    List<AppUser> members,
    List<Post> selectedPosts,
    int selectedHour,
  ) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.5,
      ),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final user = members[index];
        return MemberPostCard(
          member: user,
          post: _findPostForUser(selectedPosts, user.id),
          hourSlot: selectedHour,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.group.title} ($_currentHour시)"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<List<AppUser>>(
          future: _membersFuture,
          builder: (context, memberSnapshot) {
            if (memberSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return StreamBuilder<List<Post>>(
              stream: _postsStream,
              builder: (context, postSnapshot) {
                if (postSnapshot.hasError) {
                  return const Center(
                    child: Text(
                      "데이터 로드 중 오류가 발생했습니다.",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (postSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final members = memberSnapshot.data ?? [];
                final allDayPosts = postSnapshot.data ?? [];

                return _buildGroupContent(members, allDayPosts);
              },
            );
          },
        ),
      ),
    );
  }
}
