import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Helper/warning_snackbar.dart';
import 'package:bababam_app/Helper/ui_presets.dart';
import 'package:bababam_app/Service/firestore_service.dart';
import 'package:bababam_app/Service/today_group_video_cache_service.dart';
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

  late final TodayGroupVideoCacheService _videoCacheService;
  late final PreloadPageController _pageController;
  late Stream<List<Post>> _postsStream;
  late Future<List<AppUser>> _membersFuture;
  late int _currentHour;
  late String _todayKey;

  int? _selectedHourOverride;
  bool _useDiceLayout = false;
  final Map<String, PostTextStyleSelection> _memberTextStyleSelections = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _videoCacheService = TodayGroupVideoCacheService(
      onControllerReady: () {
        if (mounted) setState(() {});
      },
    );
    _pageController = PreloadPageController();
    _updateTime();
    _initData();
    _startClockTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _videoCacheService.disposeAll();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SocialGroupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.group.id != widget.group.id) {
      setState(() {
        _selectedHourOverride = null;
        _updateTime();
        _initData();
      });
    }
  }

  //MARK: Init Data
  void _initData() {
    _membersFuture = _firestoreService.getUsersByIds(widget.group.memberIds);
    _postsStream = _firestoreService.getPostsByDayStream(
      groupId: widget.groupId,
      dayKey: _todayKey,
    );
    _videoCacheService.prepareForDay(_todayKey);
  }

  //MARK: Time Sync
  void _updateTime() {
    final now = DateTime.now();
    _currentHour = now.hour;
    _todayKey = _generateDayKey(now);
  }

  void _startClockTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      if (now.hour != _currentHour) {
        setState(() {
          _updateTime();
          _initData();
        });
      }
    });
  }

  String _generateDayKey(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  //MARK: Timeline State
  List<int> _buildTimelineHours(List<Post> groupPosts) {
    final postedHours = groupPosts.map((post) => post.hourSlot).toSet().toList()
      ..sort();
    final timelineHours = List<int>.from(postedHours);

    if (!timelineHours.contains(_currentHour)) {
      timelineHours.add(_currentHour);
      timelineHours.sort();
    }

    return timelineHours;
  }

  int _resolveActiveHour(List<int> timelineHours) {
    if (timelineHours.isEmpty) return _currentHour;
    final requestedHour = _selectedHourOverride ?? _currentHour;
    if (timelineHours.contains(requestedHour)) return requestedHour;
    if (timelineHours.contains(_currentHour)) return _currentHour;
    return timelineHours.first;
  }

  //MARK: Page Control
  void _syncPageToIndex(int index) {
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageController.hasClients) return;
      final currentPage = _pageController.page?.round();
      if (currentPage == index) return;
      _pageController.jumpToPage(index);
    });
  }

  void _moveToTimelineIndex(List<int> timelineHours, int index) {
    if (index < 0 || index >= timelineHours.length) return;
    setState(() {
      _selectedHourOverride = timelineHours[index];
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }
  }

  //MARK: Video Preload
  void _prepareVideos({
    required List<Post> groupPosts,
    required List<int> timelineHours,
    required int currentIndex,
  }) {
    _videoCacheService.warmPosts(groupPosts);
    _videoCacheService.prepareControllersForPosts(
      _postsAroundActiveHour(
        groupPosts: groupPosts,
        timelineHours: timelineHours,
        currentIndex: currentIndex,
      ),
    );
  }

  List<Post> _postsAroundActiveHour({
    required List<Post> groupPosts,
    required List<int> timelineHours,
    required int currentIndex,
  }) {
    final preloadHours = <int>{};
    for (final index in [currentIndex - 1, currentIndex, currentIndex + 1]) {
      if (index >= 0 && index < timelineHours.length) {
        preloadHours.add(timelineHours[index]);
      }
    }

    return groupPosts
        .where((post) => preloadHours.contains(post.hourSlot))
        .toList();
  }

  CachedVideoPlayerPlusController? _controllerForPost(Post? post) {
    if (post == null) return null;
    return _videoCacheService.controllerFor(post.videoUrl);
  }

  bool _canEditPost(Post post) {
    return FirebaseAuth.instance.currentUser?.uid == post.authorId;
  }

  Future<void> _updatePostComment(Post post, String updatedComment) async {
    if (updatedComment == post.comment) return;

    try {
      await _firestoreService.updatePostComment(
        groupId: widget.groupId,
        postId: post.id,
        newComment: updatedComment,
      );
    } catch (error) {
      if (!mounted) return;
      WarningSnackBar.showWarning(context, '텍스트 수정에 실패했습니다.');
      rethrow;
    }
  }

  //MARK: Post Lookup
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

  GroupUiPreset _resolvePreset(int memberCount) {
    return AppLayoutPolicy.presetFor(
      memberCount: memberCount,
      useDiceLayout: _useDiceLayout,
    );
  }

  //MARK: Screen UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.title),
        centerTitle: true,
        actions: [_buildLayoutToggleButton()],
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

                return _buildGroupContent(
                  memberSnapshot.data ?? [],
                  postSnapshot.data ?? [],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLayoutToggleButton() {
    final memberCount = widget.group.memberIds.length;
    final canToggle =
        AppLayoutPolicy.supportsVerticalLayout(memberCount) &&
        AppLayoutPolicy.supportsDiceLayout(memberCount) &&
        !AppLayoutPolicy.isDiceOnlyMemberCount(memberCount);
    final forcedDice = AppLayoutPolicy.isDiceOnlyMemberCount(memberCount);
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
        usingDice ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
      ),
    );
  }

  //MARK: Group Content UI
  Widget _buildGroupContent(List<AppUser> members, List<Post> groupPosts) {
    final timelineHours = _buildTimelineHours(groupPosts);
    final activeHour = _resolveActiveHour(timelineHours);
    final currentIndex = timelineHours.indexOf(activeHour);
    final preset = _resolvePreset(members.length);

    _syncPageToIndex(currentIndex);
    _prepareVideos(
      groupPosts: groupPosts,
      timelineHours: timelineHours,
      currentIndex: currentIndex,
    );

    return Column(
      children: [
        _buildDotIndicator(
          timelineHours: timelineHours,
          currentIndex: currentIndex,
          groupPosts: groupPosts,
          memberCount: members.length,
        ),
        Expanded(
          child: PreloadPageView.builder(
            controller: _pageController,
            preloadPagesCount: 1,
            itemCount: timelineHours.length,
            onPageChanged: (index) {
              if (index < 0 || index >= timelineHours.length) return;
              setState(() {
                _selectedHourOverride = timelineHours[index];
              });
            },
            itemBuilder: (context, index) {
              final hour = timelineHours[index];
              final posts = groupPosts
                  .where((post) => post.hourSlot == hour)
                  .toList();
              return _buildHourPage(
                members: members,
                selectedPosts: posts,
                selectedHour: hour,
                preset: preset,
              );
            },
          ),
        ),
      ],
    );
  }

  //MARK: Timeline UI
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
                ? () => _moveToTimelineIndex(timelineHours, currentIndex - 1)
                : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(timelineHours.length, (index) {
                return _buildDotIndicatorItem(
                  timelineHours: timelineHours,
                  index: index,
                  currentIndex: currentIndex,
                  groupPosts: groupPosts,
                  memberCount: memberCount,
                );
              }),
            ),
          ),
          NavigationTriangleButton(
            isLeft: false,
            enabled: currentIndex < timelineHours.length - 1,
            onTap: currentIndex < timelineHours.length - 1
                ? () => _moveToTimelineIndex(timelineHours, currentIndex + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicatorItem({
    required List<int> timelineHours,
    required int index,
    required int currentIndex,
    required List<Post> groupPosts,
    required int memberCount,
  }) {
    final hour = timelineHours[index];
    final postCount = groupPosts.where((post) => post.hourSlot == hour).length;
    final isComplete = postCount == memberCount && postCount > 0;
    final isSelected = index == currentIndex;

    final Color indicatorColor;
    if (isSelected) {
      indicatorColor = isComplete ? const Color(0xFF7C3AED) : Colors.white;
    } else {
      indicatorColor = isComplete
          ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
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
          onTap: () => _moveToTimelineIndex(timelineHours, index),
        ),
      ),
    );
  }

  //MARK: Hour Page UI
  Widget _buildHourPage({
    required List<AppUser> members,
    required List<Post> selectedPosts,
    required int selectedHour,
    required GroupUiPreset preset,
  }) {
    final layoutSpec = preset.layoutSpec;
    if (selectedPosts.isEmpty) {
      return _buildMembersWithoutPosts(members, selectedHour);
    }
    return layoutSpec.useGrid
        ? _buildGridLayout(members, selectedPosts, selectedHour, preset)
        : _buildVerticalLayout(members, selectedPosts, selectedHour, preset);
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

  //MARK: Vertical Layout UI
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
                  child: _buildMemberPostCard(
                    user: user,
                    selectedPosts: selectedPosts,
                    selectedHour: selectedHour,
                    preset: preset,
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
              child: _buildMemberPostCard(
                user: user,
                selectedPosts: selectedPosts,
                selectedHour: selectedHour,
                preset: preset,
              ),
            ),
          )
          .toList(),
    );
  }

  //MARK: Grid Layout UI
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
            return _buildMemberPostCard(
              user: members[index],
              selectedPosts: selectedPosts,
              selectedHour: selectedHour,
              preset: preset,
            );
          },
        );
      },
    );
  }

  Widget _buildMemberPostCard({
    required AppUser user,
    required List<Post> selectedPosts,
    required int selectedHour,
    required GroupUiPreset preset,
  }) {
    final post = _findPostForUser(selectedPosts, user.id, selectedHour);
    final layoutSpec = preset.layoutSpec;

    return MemberPostCard(
      key: ValueKey('${user.id}_$selectedHour'),
      member: user,
      post: post,
      hourSlot: selectedHour,
      videoAspectRatio: layoutSpec.videoAspectRatio,
      cardRadius: preset.cardRadius,
      cardOuterMargin: preset.cardOuterMargin,
      externalVideoController: _controllerForPost(post),
      initialStyleSelection:
          _memberTextStyleSelections[user.id] ??
          AppTypography.postTextStyleSelection(
            fontId: user.fontId,
            colorId: user.colorId,
          ),
      onStyleSelectionChanged: (selection) {
        setState(() {
          _memberTextStyleSelections[user.id] = selection;
        });
        if (FirebaseAuth.instance.currentUser?.uid == user.id) {
          _firestoreService
              .updateUserTextStyle(
                userId: user.id,
                fontId: selection.fontId,
                colorId: selection.colorId,
              )
              .catchError((_) {});
        }
      },
      onSaveComment: post != null && _canEditPost(post)
          ? (comment) => _updatePostComment(post, comment)
          : null,
    );
  }
}
