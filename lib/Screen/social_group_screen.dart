import 'package:flutter/material.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Service/firestore_service.dart';
import 'package:bababam_app/Widget/member_post_card.dart';
import 'package:bababam_app/Widget/navigation_triangle_button.dart';

class SocialGroupScreen extends StatefulWidget {
  final Group group;

  const SocialGroupScreen({super.key, required this.group});

  @override
  State<SocialGroupScreen> createState() => _SocialGroupScreenState();
}

class _SocialGroupScreenState extends State<SocialGroupScreen> {
  final FireStoreService _firestoreService = FireStoreService();

  int _currentPage = 0;
  late Future<_SocialGroupData> _groupDataFuture;

  @override
  void initState() {
    super.initState();
    _groupDataFuture = _loadGroupData();
  }

  @override
  void didUpdateWidget(covariant SocialGroupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.id != widget.group.id) {
      _currentPage = 0;
      _groupDataFuture = _loadGroupData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Group currentGroup = widget.group;

    return Scaffold(
      appBar: AppBar(title: Text(currentGroup.title)),
      body: SafeArea(
        child: FutureBuilder<_SocialGroupData>(
          future: _groupDataFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  '그룹 데이터를 불러오지 못했습니다.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data;
            if (data == null) {
              return _buildEmptyState();
            }

            return _buildGroupContent(data.members, data.posts);
          },
        ),
      ),
    );
  }

  Future<_SocialGroupData> _loadGroupData() async {
    final members = await _firestoreService.getUsersByIds(
      widget.group.memberIds,
    );
    final posts = await _firestoreService.getPostsByDay(
      groupId: widget.group.id,
      dayKey: _buildDayKey(DateTime.now()),
    );

    return _SocialGroupData(members: members, posts: posts);
  }

  Widget _buildGroupContent(List<AppUser> members, List<Post> groupPosts) {
    final List<int> availableHours =
        groupPosts.map((post) => post.hourSlot).toSet().toList()..sort();
    final int currentPage = _resolveCurrentPage(availableHours);

    if (availableHours.isEmpty) {
      return _buildEmptyState();
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

  String _buildDayKey(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }
}

class _SocialGroupData {
  const _SocialGroupData({required this.members, required this.posts});

  final List<AppUser> members;
  final List<Post> posts;
}
