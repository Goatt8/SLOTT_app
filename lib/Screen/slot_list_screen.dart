import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Service/auth_service.dart';
import 'package:bababam_app/Service/firestore_service.dart';
import 'package:bababam_app/Service/post_video_cleanup_service.dart';
import 'package:bababam_app/Screen/create_slot_screen.dart';
import 'package:bababam_app/Screen/slot_group_screen.dart';
import 'package:bababam_app/Screen/profile_edit_screen.dart';
import 'package:bababam_app/Widget/group_list_cell.dart';
import 'package:bababam_app/Widget/glass_popup_menu.dart';
import 'package:bababam_app/Widget/confirm_dialog.dart';
import 'package:bababam_app/Widget/code_input_dialog.dart';
import 'package:bababam_app/Widget/blocked_users_dialog.dart';
import 'package:bababam_app/Helper/warning_snackbar.dart';

class SlotListScreen extends StatefulWidget {
  const SlotListScreen({super.key});

  @override
  State<SlotListScreen> createState() => _SlotListScreenState();
}

class _SlotListScreenState extends State<SlotListScreen> {
  final AuthService _authService = AuthService();
  final FireStoreService _firestoreService = FireStoreService();
  final PostVideoCleanupService _postVideoCleanupService =
      PostVideoCleanupService();
  final Set<String> _dismissedGroupIds = {};
  bool _didRunStartupVideoCleanup = false;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;

    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  void _runStartupVideoCleanup(List<Group> groups) {
    if (_didRunStartupVideoCleanup || groups.isEmpty) return;
    _didRunStartupVideoCleanup = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final group in groups) {
        try {
          await _postVideoCleanupService.deleteGroupPostVideosOlderThan(
            groupId: group.id,
          );
        } catch (error) {
          debugPrint('오래된 그룹 영상 정리 실패(${group.id}): $error');
        }
      }
    });
  }

  //MARK: Navigation Create Grouo
  void _navigateAndAddGroup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateSlotScreen()),
    );
  }

  //MARK: Navigation Profile
  Future<void> _navigateToEditProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(currentUserId: currentUser.uid),
      ),
    );

    setState(() {
      //MARK: pop뒤 로직
    });
  }

  Future<void> _showBlockedUsers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final unblockedCount = await showDialog<int>(
      context: context,
      builder: (context) => BlockedUsersDialog(
        currentUserId: currentUser.uid,
        firestoreService: _firestoreService,
      ),
    );

    if (!mounted || unblockedCount == null || unblockedCount == 0) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$unblockedCount명의 차단을 해제했습니다.')));
  }

  Widget _buildGroupList() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('로그인이 필요합니다.', style: TextStyle(color: Colors.white54)),
      );
    }

    return StreamBuilder<AppUser?>(
      stream: _firestoreService.watchUser(currentUser.uid),
      builder: (context, userSnapshot) {
        final unreadGroupIds = userSnapshot.data?.unreadGroupIds.toSet() ?? {};

        return StreamBuilder<List<Group>>(
          stream: _firestoreService.watchGroupsForUser(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  '그룹을 불러오지 못했습니다.',
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final groups = snapshot.data ?? [];
            final visibleGroups = groups
                .where((group) => !_dismissedGroupIds.contains(group.id))
                .toList();
            _runStartupVideoCleanup(groups);

            if (visibleGroups.isEmpty) {
              return const Center(
                child: Text(
                  '아직 생성된 그룹이 없습니다',
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }
            //MARK: ListView
            return ListView.builder(
              itemCount: visibleGroups.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final group = visibleGroups[index];
                final hasUnreadGroup = unreadGroupIds.contains(group.id);

                void openGroup() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SlotGroupScreen(group: group, groupId: group.id),
                    ),
                  );

                  if (hasUnreadGroup) {
                    unawaited(
                      _firestoreService.markGroupNotificationRead(
                        userId: currentUser.uid,
                        groupId: group.id,
                      ),
                    );
                  }
                }

                return Dismissible(
                  key: Key(group.id),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (context) => ConfirmDialog(
                            title: group.ownerId == currentUser.uid
                                ? '슬롯 그룹 삭제'
                                : '슬롯 그룹 나가기',
                            message: group.ownerId == currentUser.uid
                                ? '${group.title} 슬롯 그룹을 삭제하시겠습니까?'
                                : '${group.title} 슬롯 그룹에서 나가시겠습니까?',
                          ),
                        ) ??
                        false;
                  },
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    setState(() => _dismissedGroupIds.add(group.id));
                    _removeGroup(group, currentUser.uid);
                  },
                  child: InkWell(
                    onTap: openGroup,
                    child: FutureBuilder<List<String>>(
                      future: _loadMemberNames(group.memberIds),
                      builder: (context, snapshot) {
                        return GroupListCell(
                          group: group,
                          memberNames: snapshot.data ?? const [],
                          hasUnreadGroup: hasUnreadGroup,
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<String>> _loadMemberNames(List<String> memberIds) async {
    final users = await _firestoreService.getUsersByIds(memberIds);
    return users
        .map((user) => user.name)
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Future<void> _joinGroup(String? code) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final groupId = code?.trim();

    if (currentUser == null || groupId == null || groupId.isEmpty) {
      return;
    }

    try {
      await _firestoreService.joinGroup(
        groupId: groupId,
        userId: currentUser.uid,
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().contains('Group is full')
          ? '그룹 정원이 가득 찼습니다.'
          : '슬롯 참여에 실패했습니다.';
      WarningSnackBar.showWarning(context, message);
    }
  }

  Future<void> _removeGroup(Group group, String userId) async {
    try {
      if (group.ownerId == userId) {
        final videoFiles = await _firestoreService.getGroupPostVideoFiles(
          group.id,
        );
        try {
          await _postVideoCleanupService.deleteVideos(videoFiles);
        } catch (error) {
          debugPrint('그룹 영상 Storage 삭제 실패(${group.id}): $error');
        }
        await _firestoreService.deleteGroup(group.id);
      } else {
        await _firestoreService.leaveGroup(groupId: group.id, userId: userId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _dismissedGroupIds.remove(group.id));
      WarningSnackBar.showWarning(context, '그룹 변경에 실패했습니다.');
    }
  }

  void _showGlassMenu(
    BuildContext context, {
    required Alignment alignment,
    required Widget menu,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(alignment: alignment, child: menu);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          alignment: alignment + const Alignment(0, -0.1),
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //MARK: Top title
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 26,
              child: Image.asset(
                'assets/logo/logo.jpeg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            if (_appVersion != null) ...[
              const SizedBox(width: 8),
              Text(
                'ver $_appVersion',
                style: const TextStyle(
                  color: Color(0x66FFFFFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          //MARK: Add Button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showGlassMenu(
                context,
                alignment: const Alignment(0.5, -0.75),
                menu: GlassPopupMenu(
                  items: [
                    GlassMenuItem(
                      title: '슬롯 만들기',
                      icon: Icons.add_circle_outline,
                      onTap: _navigateAndAddGroup,
                    ),
                    GlassMenuItem(
                      title: '슬롯 참여하기',
                      icon: Icons.group_add_outlined,
                      onTap: () async {
                        final String? code = await showDialog<String>(
                          context: context,
                          builder: (context) => const CodeInputDialog(),
                        );

                        await _joinGroup(code);
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          _buildProfileMenuButton(),
        ],
      ),
      body: _buildGroupList(),
    );
  }

  Widget _buildProfileMenuButton() {
    return IconButton(
      icon: const Icon(Icons.person_outline),
      onPressed: () async {
        _showGlassMenu(
          context,
          alignment: const Alignment(0.9, -0.75),
          menu: GlassPopupMenu(
            width: 180,
            items: [
              //MARK: Profile Button
              GlassMenuItem(
                title: '내 프로필',
                icon: Icons.account_circle_outlined,
                onTap: () {
                  _navigateToEditProfile();
                },
              ),
              GlassMenuItem(
                title: '차단 목록 관리',
                icon: Icons.manage_accounts_outlined,
                onTap: _showBlockedUsers,
              ),
              //MARK: Logout Button
              GlassMenuItem(
                title: '로그아웃',
                icon: Icons.logout,
                onTap: () async {
                  final rootContext = context;
                  final bool? isConfirmed = await showDialog<bool>(
                    context: rootContext,
                    builder: (context) => const ConfirmDialog(
                      title: '로그아웃',
                      message: '정말 로그아웃 하시겠습니까?',
                    ),
                  );
                  if (isConfirmed == true) {
                    try {
                      await _authService.signOut();
                      if (!rootContext.mounted) return;
                      Navigator.of(
                        rootContext,
                      ).pushNamedAndRemoveUntil('/login', (route) => false);
                    } catch (e) {
                      if (!rootContext.mounted) return;
                      WarningSnackBar.showWarning(rootContext, "로그아웃에 실패했습니다.");
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
