import 'package:flutter/material.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Service/firestore_service.dart';

class BlockedUsersDialog extends StatefulWidget {
  const BlockedUsersDialog({
    super.key,
    required this.currentUserId,
    required this.firestoreService,
  });

  final String currentUserId;
  final FireStoreService firestoreService;

  @override
  State<BlockedUsersDialog> createState() => _BlockedUsersDialogState();
}

class _BlockedUsersDialogState extends State<BlockedUsersDialog> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  Set<String> _initialBlockedUserIds = {};
  Set<String> _selectedBlockedUserIds = {};
  List<AppUser> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final currentUser = await widget.firestoreService.getUser(
        widget.currentUserId,
      );
      if (currentUser == null) {
        throw StateError('현재 사용자 문서를 찾을 수 없습니다.');
      }

      final blockedUserIds = currentUser.blockedUserIds.toSet();
      final users = await widget.firestoreService.getUsersByIds(
        blockedUserIds.toList(),
      );
      if (!mounted) return;
      setState(() {
        _initialBlockedUserIds = blockedUserIds;
        _selectedBlockedUserIds = {...blockedUserIds};
        _blockedUsers = users;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('차단 목록 조회 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _loadError = '차단 목록을 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final userIdsToUnblock = _initialBlockedUserIds.difference(
      _selectedBlockedUserIds,
    );

    setState(() => _isSaving = true);
    try {
      await widget.firestoreService.unblockUsers(
        userId: widget.currentUserId,
        blockedUserIds: userIdsToUnblock,
      );
      if (!mounted) return;
      Navigator.of(context).pop(userIdsToUnblock.length);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('차단 목록 변경에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('차단 목록 관리'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              )
            : _buildUserList(),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _isLoading || _isSaving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text('확인'),
        ),
      ],
    );
  }

  Widget _buildUserList() {
    if (_loadError != null) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            _loadError!,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    if (_initialBlockedUserIds.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            '차단한 사용자가 없습니다.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    final userById = {for (final user in _blockedUsers) user.id: user};
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _initialBlockedUserIds.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final userId = _initialBlockedUserIds.elementAt(index);
          final user = userById[userId];
          final isBlocked = _selectedBlockedUserIds.contains(userId);

          return SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: isBlocked,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.redAccent,
            title: Text(user?.name ?? '알 수 없는 사용자'),
            secondary: CircleAvatar(
              backgroundColor: Colors.white12,
              backgroundImage: user?.profileUrl == null
                  ? null
                  : NetworkImage(user!.profileUrl!),
              child: user?.profileUrl == null
                  ? const Icon(Icons.person, color: Colors.white54)
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                if (value) {
                  _selectedBlockedUserIds.add(userId);
                } else {
                  _selectedBlockedUserIds.remove(userId);
                }
              });
            },
          );
        },
      ),
    );
  }
}
