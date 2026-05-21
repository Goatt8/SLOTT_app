import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Helper/ui_presets.dart';
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
  int? _selectedHourOverride;
  bool _useDiceLayout = false;
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
        _selectedHourOverride = null;
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
    final List<int> postedHours =
        groupPosts.map((post) => post.hourSlot).toSet().toList()..sort();

    final int activeHour = _selectedHourOverride ?? _currentHour;

    final List<int> timelineHours = List<int>.from(postedHours);
    if (!timelineHours.contains(_currentHour)) {
      timelineHours.add(_currentHour);
      timelineHours.sort();
    }

    final int currentIndex = timelineHours.indexOf(activeHour);

    final List<Post> selectedPosts = groupPosts
        .where((post) => post.hourSlot == activeHour)
        .toList();

    final preset = _resolvePreset(members.length);
    final layoutSpec = preset.layoutSpec;

    return Column(
      children: [
        _buildDotIndicator(
          timelineHours: timelineHours,
          currentIndex: currentIndex,
          groupPosts: groupPosts,
          memberCount: members.length,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: selectedPosts.isEmpty
                ? _buildMembersWithoutPosts(members, activeHour)
                : (layoutSpec.useGrid
                      ? _buildGridLayout(
                          members,
                          selectedPosts,
                          activeHour,
                          preset,
                        )
                      : _buildVerticalLayout(
                          members,
                          selectedPosts,
                          activeHour,
                          preset,
                        )),
          ),
        ),
      ],
    );
  }

  int _resolveCurrentPage(List<int> availableHours) {
    if (availableHours.isEmpty) {
      _currentPage = 0;
      _selectedHourOverride = null;
      return 0;
    }

    if (_selectedHourOverride != null) {
      final int selectedIndex = availableHours.indexOf(_selectedHourOverride!);
      if (selectedIndex != -1) {
        _currentPage = selectedIndex;
        return _currentPage;
      }
      _selectedHourOverride = null;
    }

    final int currentHourIndex = availableHours.indexOf(_currentHour);
    if (currentHourIndex != -1) {
      _currentPage = currentHourIndex;
      _selectedHourOverride = availableHours[_currentPage];
      return _currentPage;
    }

    if (_currentPage < 0 || _currentPage >= availableHours.length) {
      _currentPage = 0;
    }
    _selectedHourOverride = availableHours[_currentPage];

    return _currentPage;
  }

  //MARK: FindUserHour
  Post? _findPostForUser(List<Post> posts, String userId, int targetHour) {
    Post? targetPost;
    for (final post in posts) {
      if (post.authorId != userId) continue;
      if (post.hourSlot != targetHour) continue;

      if (targetPost == null || post.createdAt.isAfter(targetPost.createdAt)) {
        targetPost = post;
      }
    }
    return targetPost;
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        '아직 올라온 시간대가 없어요',
        style: TextStyle(color: Colors.white54, fontSize: 13),
      ),
    );
  }

  Widget _buildMembersWithoutPosts(List<AppUser> members, int targetHour) {
    if (members.isEmpty) {
      return const Center(
        child: Text(
          '아직 올라온 시간대가 없어요',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    final preset = _resolvePreset(members.length);
    final layoutSpec = preset.layoutSpec;

    if (layoutSpec.useGrid) {
      return _buildGridLayout(members, const <Post>[], targetHour, preset);
    }

    return Column(
      children: members
          .map(
            (user) => Expanded(
              child: MemberPostCard(
                key: ValueKey('${user.id}_$targetHour'),
                member: user,
                post: null,
                hourSlot: targetHour,
                cardRadius: preset.cardRadius,
                cardOuterMargin: preset.cardOuterMargin,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDotIndicator({
    required List<int> timelineHours,
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
                      _selectedHourOverride = timelineHours[currentIndex - 1];
                    });
                  }
                : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(timelineHours.length, (index) {
                final hour = timelineHours[index];
                final int postCount = groupPosts
                    .where((post) => post.hourSlot == hour)
                    .length;
                final bool isComplete =
                    postCount == memberCount && postCount > 0;
                final bool isSelected = index == currentIndex;

                // 인디케이터 색상 로직 보정
                Color indicatorColor;
                if (isSelected) {
                  indicatorColor = isComplete
                      ? const Color(0xFF7C3AED)
                      : Colors.white;
                } else {
                  indicatorColor = isComplete
                      ? const Color(0xFF7C3AED).withOpacity(0.5)
                      : Colors.white24;
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
                          _selectedHourOverride = hour;
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
            enabled: currentIndex < timelineHours.length - 1,
            onTap: currentIndex < timelineHours.length - 1
                ? () {
                    setState(() {
                      _selectedHourOverride = timelineHours[currentIndex + 1];
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  //MARK: Vertical Layout
  Widget _buildVerticalLayout(
    List<AppUser> members,
    List<Post> selectedPosts,
    int selectedHour,
    GroupUiPreset preset,
  ) {
    final layoutSpec = preset.layoutSpec;
    if (layoutSpec.compactVerticalCards) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        children: members
            .map(
              (user) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: AspectRatio(
                  aspectRatio: layoutSpec.videoAspectRatio,
                  child: MemberPostCard(
                    key: ValueKey('${user.id}_$selectedHour'),
                    member: user,
                    post: _findPostForUser(
                      selectedPosts,
                      user.id,
                      selectedHour,
                    ),
                    hourSlot: selectedHour,
                    videoAspectRatio: layoutSpec.videoAspectRatio,
                    cardRadius: preset.cardRadius,
                    cardOuterMargin: preset.cardOuterMargin,
                  ),
                ),
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: members
          .map(
            (user) => Expanded(
              child: MemberPostCard(
                member: user,
                post: _findPostForUser(selectedPosts, user.id, selectedHour),
                hourSlot: selectedHour,
                videoAspectRatio: layoutSpec.videoAspectRatio,
                cardRadius: preset.cardRadius,
                cardOuterMargin: preset.cardOuterMargin,
              ),
            ),
          )
          .toList(),
    );
  }

  //MARK: Grid Layout
  Widget _buildGridLayout(
    List<AppUser> members,
    List<Post> selectedPosts,
    int selectedHour,
    GroupUiPreset preset,
  ) {
    final layoutSpec = preset.layoutSpec;
    final slotCount = layoutSpec.fixedSlotCount ?? members.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = preset.gridHorizontalPadding;
        final verticalPadding = preset.gridVerticalPadding;
        final spacing = preset.gridSpacing;

        final columns = layoutSpec.crossAxisCount;
        final rows = (slotCount / columns).ceil();
        final availableWidth =
            constraints.maxWidth -
            (horizontalPadding * 2) -
            (spacing * (columns - 1));
        final availableHeight =
            constraints.maxHeight -
            (verticalPadding * 2) -
            (spacing * (rows - 1));
        final tileWidth = availableWidth / columns;
        final tileHeight = availableHeight / rows;
        final fillAspectRatio = tileWidth / tileHeight;
        final childAspectRatio = preset.fillGridViewport
            ? fillAspectRatio
            : layoutSpec.gridChildAspectRatio;

        return GridView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: slotCount,
          itemBuilder: (context, index) {
            if (index >= members.length) {
              return const SizedBox.shrink();
            }
            final user = members[index];
            return MemberPostCard(
              key: ValueKey('${user.id}_$selectedHour'),
              member: user,
              post: _findPostForUser(selectedPosts, user.id, selectedHour),
              hourSlot: selectedHour,
              videoAspectRatio: layoutSpec.videoAspectRatio,
              cardRadius: preset.cardRadius,
              cardOuterMargin: preset.cardOuterMargin,
            );
          },
        );
      },
    );
  }

  GroupUiPreset _resolvePreset(int memberCount) {
    return AppLayoutPolicy.presetFor(
      memberCount: memberCount,
      useDiceLayout: _useDiceLayout,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.group.title} ($_currentHour시)"),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) {
              final memberCount = widget.group.memberIds.length;
              final canToggle =
                  AppLayoutPolicy.supportsVerticalLayout(memberCount) &&
                  AppLayoutPolicy.supportsDiceLayout(memberCount) &&
                  !AppLayoutPolicy.isDiceOnlyMemberCount(memberCount);
              final forcedDice = AppLayoutPolicy.isDiceOnlyMemberCount(
                memberCount,
              );
              final usingDice = forcedDice || _useDiceLayout;
              return IconButton(
                tooltip: usingDice ? '기본 레이아웃' : '주사위 레이아웃',
                onPressed: canToggle
                    ? () {
                        setState(() {
                          _useDiceLayout = !_useDiceLayout;
                        });
                      }
                    : null,
                icon: Icon(
                  usingDice
                      ? Icons.view_agenda_rounded
                      : Icons.grid_view_rounded,
                ),
              );
            },
          ),
        ],
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
