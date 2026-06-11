import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Helper/warning_snackbar.dart';
import 'package:bababam_app/Helper/ui_presets.dart';
import 'package:bababam_app/Helper/content_moderation.dart';
import 'package:bababam_app/Service/firestore_service.dart';
import 'package:bababam_app/Service/today_group_video_cache_service.dart';
import 'package:bababam_app/Widget/member_post_card.dart';
import 'package:bababam_app/Widget/navigation_triangle_button.dart';

class SlotGroupScreen extends StatefulWidget {
  final Group group;
  final String groupId;

  const SlotGroupScreen({
    super.key,
    required this.group,
    required this.groupId,
  });

  @override
  State<SlotGroupScreen> createState() => _SlotGroupScreenState();
}

class _SlotGroupScreenState extends State<SlotGroupScreen> {
  final FireStoreService _firestoreService = FireStoreService();

  late final TodayGroupVideoCacheService _videoCacheService;
  late final PreloadPageController _pageController;
  late Stream<List<Post>> _postsStream;
  late Future<List<AppUser>> _membersFuture;
  late Group _activeGroup;
  late int _currentHour;
  late String _todayKey;

  int? _selectedHourOverride;
  bool _useDiceLayout = false;
  PostTextStyleSelection? _viewerTextStyleSelection;
  Timer? _timer;
  StreamSubscription<Set<String>>? _blockedUsersSubscription;
  Set<String> _blockedUserIds = {};

  @override
  void initState() {
    super.initState();
    _videoCacheService = TodayGroupVideoCacheService(
      onControllerReady: () {
        if (mounted) setState(() {});
      },
    );
    _pageController = PreloadPageController();
    _activeGroup = widget.group;
    _updateTime();
    _initData();
    _watchBlockedUsers();
    _startClockTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blockedUsersSubscription?.cancel();
    _pageController.dispose();
    _videoCacheService.disposeAll();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SlotGroupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.group.id != widget.group.id) {
      setState(() {
        _activeGroup = widget.group;
        _selectedHourOverride = null;
        _updateTime();
        _initData();
      });
    }
  }

  //MARK: Init Data
  void _initData() {
    _membersFuture = _firestoreService.getUsersByIds(_activeGroup.memberIds);
    _postsStream = _firestoreService.getPostsByDayStream(
      groupId: widget.groupId,
      dayKey: _todayKey,
    );
    _videoCacheService.prepareForDay(_todayKey);
  }

  void _watchBlockedUsers() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _blockedUsersSubscription = _firestoreService
        .watchBlockedUserIds(currentUserId)
        .listen((blockedUserIds) {
          if (!mounted) return;
          setState(() {
            _blockedUserIds = blockedUserIds;
          });
        });
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
    final preloadPosts = _postsAroundActiveHour(
      groupPosts: groupPosts,
      timelineHours: timelineHours,
      currentIndex: currentIndex,
    );
    _videoCacheService.warmPosts(preloadPosts);
    _videoCacheService.prepareControllersForPosts(preloadPosts);
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

  void _copyInviteCode() {
    Clipboard.setData(ClipboardData(text: widget.group.id));
    if (!mounted) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('그룹 ID를 복사했습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _claimSlot(int slotIndex) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _firestoreService.claimGroupSlot(
        groupId: widget.groupId,
        userId: currentUserId,
        slotIndex: slotIndex,
      );

      if (!mounted) return;
      final slotOwnerIds = _activeGroup.effectiveSlotOwnerIds;
      slotOwnerIds[slotIndex] = currentUserId;
      final memberIds = _activeGroup.memberIds.contains(currentUserId)
          ? _activeGroup.memberIds
          : [..._activeGroup.memberIds, currentUserId];

      setState(() {
        _activeGroup = _activeGroup.copyWith(
          memberIds: memberIds,
          slotOwnerIds: slotOwnerIds,
        );
        _membersFuture = _firestoreService.getUsersByIds(memberIds);
      });
    } catch (_) {
      if (!mounted) return;
      WarningSnackBar.showWarning(context, '빈 자리에 들어가지 못했습니다.');
    }
  }

  bool _canEditPost(Post post) {
    return FirebaseAuth.instance.currentUser?.uid == post.authorId;
  }

  Future<void> _updatePostComment(Post post, String updatedComment) async {
    if (updatedComment == post.comment) return;
    final moderationMessage = ContentModeration.rejectionMessage(
      updatedComment,
    );
    if (moderationMessage != null) {
      WarningSnackBar.showWarning(context, moderationMessage);
      throw StateError(moderationMessage);
    }

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

  Future<String?> _selectReportReason() {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('신고 사유를 선택해주세요'),
          children: [
            for (final reason in const [
              '괴롭힘 또는 혐오 표현',
              '음란물 또는 성적인 콘텐츠',
              '폭력적이거나 위험한 콘텐츠',
              '개인정보 침해',
              '스팸 또는 사기',
              '기타 부적절한 콘텐츠',
            ])
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(reason),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(reason),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _reportPost(Post post, AppUser user) async {
    final reporterId = FirebaseAuth.instance.currentUser?.uid;
    if (reporterId == null || reporterId == user.id) return;

    final reason = await _selectReportReason();
    if (reason == null) return;

    try {
      await _firestoreService.reportPost(
        reporterId: reporterId,
        reportedUserId: user.id,
        groupId: widget.groupId,
        post: post,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('신고가 접수되었습니다. 24시간 이내에 검토하겠습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      WarningSnackBar.showWarning(context, '신고 접수에 실패했습니다.');
    }
  }

  Future<void> _blockUser(Post? post, AppUser user) async {
    final reporterId = FirebaseAuth.instance.currentUser?.uid;
    if (reporterId == null || reporterId == user.id) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('사용자 차단'),
          content: Text('${user.name}님을 차단하면 이 사용자의 콘텐츠가 즉시 숨겨지고 운영자에게 신고됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('차단 및 신고'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _blockedUserIds = {..._blockedUserIds, user.id};
    });

    try {
      await _firestoreService.blockUserAndReport(
        reporterId: reporterId,
        blockedUserId: user.id,
        groupId: widget.groupId,
        post: post,
        reason: '사용자 차단',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용자를 차단했으며 운영자에게 신고했습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _blockedUserIds = {..._blockedUserIds}..remove(user.id);
      });
      WarningSnackBar.showWarning(context, '사용자 차단에 실패했습니다.');
    }
  }

  //MARK: Post Lookup
  Post? _findExactPostForSlot({
    required List<Post> posts,
    required int slotIndex,
    required int targetHour,
  }) {
    Post? targetPost;
    for (final post in posts) {
      if (post.hourSlot != targetHour) continue;
      if (post.slotIndex != slotIndex) continue;

      if (targetPost == null || post.createdAt.isAfter(targetPost.createdAt)) {
        targetPost = post;
      }
    }
    return targetPost;
  }

  Post? _findPostForSlot({
    required List<Post> posts,
    required int slotIndex,
    required String ownerId,
    required int targetHour,
    required bool allowLegacyUserFallback,
  }) {
    Post? targetPost = _findExactPostForSlot(
      posts: posts,
      slotIndex: slotIndex,
      targetHour: targetHour,
    );

    if (targetPost != null || !allowLegacyUserFallback) {
      return targetPost;
    }

    for (final post in posts) {
      if (post.hourSlot != targetHour) continue;
      if (post.slotIndex != -1 || post.authorId != ownerId) continue;

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
        toolbarHeight: 44,
        title: Text(widget.group.title),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        centerTitle: true,
        titleSpacing: 0,
        actions: [_buildLayoutToggleButton()],
      ),
      body: SafeArea(
        child: FutureBuilder<List<AppUser>>(
          future: _membersFuture,
          builder: (context, memberSnapshot) {
            if (memberSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (memberSnapshot.hasError) {
              debugPrint('소셜 그룹 멤버 로드 오류: ${memberSnapshot.error}');
              return const Center(
                child: Text(
                  "멤버 데이터를 불러오지 못했습니다.",
                  style: TextStyle(color: Colors.redAccent),
                ),
              );
            }

            return StreamBuilder<List<Post>>(
              stream: _postsStream,
              builder: (context, postSnapshot) {
                if (postSnapshot.hasError) {
                  debugPrint('소셜 그룹 포스트 로드 오류: ${postSnapshot.error}');
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
    final memberCount = widget.group.slotCount;
    final canToggle =
        AppLayoutPolicy.supportsVerticalLayout(memberCount) &&
        AppLayoutPolicy.supportsDiceLayout(memberCount) &&
        !AppLayoutPolicy.isDiceOnlyMemberCount(memberCount);
    final forcedDice = AppLayoutPolicy.isDiceOnlyMemberCount(memberCount);
    final usingDice = forcedDice || _useDiceLayout;

    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        tooltip: usingDice ? '기본 레이아웃' : '주사위 레이아웃',
        padding: EdgeInsets.zero,
        onPressed: canToggle
            ? () {
                setState(() {
                  _useDiceLayout = !_useDiceLayout;
                });
              }
            : null,
        icon: Icon(
          usingDice ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
          size: 21,
        ),
      ),
    );
  }

  //MARK: Group Content UI
  Widget _buildGroupContent(List<AppUser> members, List<Post> groupPosts) {
    final visibleGroupPosts = groupPosts
        .where((post) => !_blockedUserIds.contains(post.authorId))
        .toList();
    final slotOwnerIds = _activeGroup.effectiveSlotOwnerIds;
    final userById = {for (final member in members) member.id: member};
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final viewer = currentUserId == null ? null : userById[currentUserId];
    final viewerTextStyleSelection =
        _viewerTextStyleSelection ??
        AppTypography.postTextStyleSelection(
          fontId: viewer?.fontId,
          colorId: viewer?.colorId,
          hourFontId: viewer?.hourFontId,
        );
    final slotCount = slotOwnerIds.length;
    final timelineHours = _buildTimelineHours(visibleGroupPosts);
    final activeHour = _resolveActiveHour(timelineHours);
    final currentIndex = timelineHours.indexOf(activeHour);
    final preset = _resolvePreset(slotCount);

    _syncPageToIndex(currentIndex);
    _prepareVideos(
      groupPosts: visibleGroupPosts,
      timelineHours: timelineHours,
      currentIndex: currentIndex,
    );

    return Column(
      children: [
        _buildDotIndicator(
          timelineHours: timelineHours,
          currentIndex: currentIndex,
          groupPosts: visibleGroupPosts,
          memberCount: slotCount,
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
              final posts = visibleGroupPosts
                  .where((post) => post.hourSlot == hour)
                  .toList();
              return _buildHourPage(
                slotOwnerIds: slotOwnerIds,
                userById: userById,
                selectedPosts: posts,
                selectedHour: hour,
                slotCount: slotCount,
                preset: preset,
                viewerTextStyleSelection: viewerTextStyleSelection,
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
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
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
    final accentColor = Theme.of(context).colorScheme.primary;

    final Color indicatorColor;
    if (isSelected) {
      indicatorColor = isComplete ? accentColor : Colors.white;
    } else {
      indicatorColor = isComplete
          ? accentColor.withValues(alpha: 0.5)
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
    required List<String?> slotOwnerIds,
    required Map<String, AppUser> userById,
    required List<Post> selectedPosts,
    required int selectedHour,
    required int slotCount,
    required GroupUiPreset preset,
    required PostTextStyleSelection viewerTextStyleSelection,
  }) {
    final layoutSpec = preset.layoutSpec;
    return layoutSpec.useGrid
        ? _buildGridLayout(
            slotOwnerIds,
            userById,
            selectedPosts,
            selectedHour,
            slotCount,
            preset,
            viewerTextStyleSelection,
          )
        : _buildVerticalLayout(
            slotOwnerIds,
            userById,
            selectedPosts,
            selectedHour,
            slotCount,
            preset,
            viewerTextStyleSelection,
          );
  }

  //MARK: Vertical Layout UI
  Widget _buildVerticalLayout(
    List<String?> slotOwnerIds,
    Map<String, AppUser> userById,
    List<Post> selectedPosts,
    int selectedHour,
    int slotCount,
    GroupUiPreset preset,
    PostTextStyleSelection viewerTextStyleSelection,
  ) {
    return Column(
      children: List.generate(slotCount, (index) {
        final ownerId = index < slotOwnerIds.length
            ? slotOwnerIds[index]
            : null;
        final user = ownerId == null ? null : userById[ownerId];
        return Expanded(
          child: user != null
              ? _buildMemberPostCard(
                  user: user,
                  slotIndex: index,
                  selectedPosts: selectedPosts,
                  selectedHour: selectedHour,
                  preset: preset,
                  viewerTextStyleSelection: viewerTextStyleSelection,
                )
              : _buildInviteSlotCard(
                  slotIndex: index,
                  selectedHour: selectedHour,
                  preset: preset,
                ),
        );
      }),
    );
  }

  Widget _buildInviteSlotCard({
    required int slotIndex,
    required int selectedHour,
    required GroupUiPreset preset,
  }) {
    return Container(
      key: ValueKey('invite_${slotIndex}_$selectedHour'),
      margin: EdgeInsets.all(preset.cardOuterMargin),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(preset.cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: _copyInviteCode,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('초대링크복사'),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: () => _claimSlot(slotIndex),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('내 슬롯으로 채우기'),
            ),
          ],
        ),
      ),
    );
  }

  //MARK: Grid Layout UI
  Widget _buildGridLayout(
    List<String?> slotOwnerIds,
    Map<String, AppUser> userById,
    List<Post> selectedPosts,
    int selectedHour,
    int slotCount,
    GroupUiPreset preset,
    PostTextStyleSelection viewerTextStyleSelection,
  ) {
    final layoutSpec = preset.layoutSpec;
    final gridSlotCount = layoutSpec.fixedSlotCount ?? slotCount;
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = preset.gridHorizontalPadding;
        final verticalPadding = preset.gridVerticalPadding;
        final spacing = preset.gridSpacing;

        final columns = layoutSpec.crossAxisCount;
        final rows = (gridSlotCount / columns).ceil();
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
          itemCount: gridSlotCount,
          itemBuilder: (context, index) {
            if (index >= slotCount) {
              return const SizedBox.shrink();
            }

            final ownerId = index < slotOwnerIds.length
                ? slotOwnerIds[index]
                : null;
            final user = ownerId == null ? null : userById[ownerId];

            if (user == null) {
              return _buildInviteSlotCard(
                slotIndex: index,
                selectedHour: selectedHour,
                preset: preset,
              );
            }
            return _buildMemberPostCard(
              user: user,
              slotIndex: index,
              selectedPosts: selectedPosts,
              selectedHour: selectedHour,
              preset: preset,
              viewerTextStyleSelection: viewerTextStyleSelection,
            );
          },
        );
      },
    );
  }

  Widget _buildMemberPostCard({
    required AppUser user,
    required int slotIndex,
    required List<Post> selectedPosts,
    required int selectedHour,
    required GroupUiPreset preset,
    required PostTextStyleSelection viewerTextStyleSelection,
  }) {
    if (_blockedUserIds.contains(user.id)) {
      return _buildBlockedMemberCard(
        preset: preset,
        selectedHour: selectedHour,
      );
    }

    final exactSlotPost = user.isDeleted
        ? null
        : _findExactPostForSlot(
            posts: selectedPosts,
            slotIndex: slotIndex,
            targetHour: selectedHour,
          );
    final post = user.isDeleted
        ? null
        : _findPostForSlot(
            posts: selectedPosts,
            slotIndex: slotIndex,
            ownerId: user.id,
            targetHour: selectedHour,
            allowLegacyUserFallback:
                _activeGroup.effectiveSlotOwnerIds
                    .where((ownerId) => ownerId == user.id)
                    .length ==
                1,
          );
    final layoutSpec = preset.layoutSpec;

    return MemberPostCard(
      key: ValueKey('${user.id}_${slotIndex}_$selectedHour'),
      member: user,
      post: post,
      hourSlot: selectedHour,
      videoAspectRatio: layoutSpec.videoAspectRatio,
      cardRadius: preset.cardRadius,
      cardOuterMargin: preset.cardOuterMargin,
      hourOverlaySpec: preset.hourOverlaySpec,
      externalVideoController: _controllerForPost(post),
      initialStyleSelection: viewerTextStyleSelection,
      onStyleSelectionChanged: (selection) {
        setState(() {
          _viewerTextStyleSelection = selection;
        });
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          _firestoreService
              .updateUserTextStyle(
                userId: currentUserId,
                fontId: selection.fontId,
                colorId: selection.colorId,
                hourFontId: selection.hourFontId,
              )
              .catchError((_) {});
        }
      },
      onSaveComment: exactSlotPost != null && _canEditPost(exactSlotPost)
          ? (comment) => _updatePostComment(exactSlotPost, comment)
          : null,
      onReport:
          post != null && FirebaseAuth.instance.currentUser?.uid != user.id
          ? () => _reportPost(post, user)
          : null,
      onBlock: FirebaseAuth.instance.currentUser?.uid != user.id
          ? () => _blockUser(post, user)
          : null,
    );
  }

  Widget _buildBlockedMemberCard({
    required GroupUiPreset preset,
    required int selectedHour,
  }) {
    return MemberPostCard(
      member: AppUser(
        id: 'blocked',
        name: '차단한 사용자',
        phoneNumber: '',
        isDeleted: true,
      ),
      post: null,
      hourSlot: selectedHour,
      videoAspectRatio: preset.layoutSpec.videoAspectRatio,
      cardRadius: preset.cardRadius,
      cardOuterMargin: preset.cardOuterMargin,
      hourOverlaySpec: preset.hourOverlaySpec,
    );
  }
}
