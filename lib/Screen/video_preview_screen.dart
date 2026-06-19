import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bababam_app/Helper/ui_presets.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Helper/warning_snackbar.dart';
import 'package:bababam_app/Helper/content_moderation.dart';
import 'package:bababam_app/Service/firestore_service.dart';
import 'package:bababam_app/Service/firestorage_service.dart';
import 'package:bababam_app/Widget/post_comment_overlay.dart';
import 'package:bababam_app/Widget/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String videoPath;

  const VideoPreviewScreen({super.key, required this.videoPath});

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  final Map<String, Set<int>> _selectedSlotIndexesByGroupId = {};
  final FireStoreService _firestoreService = FireStoreService();
  final FireStorageService _fireStorageService = FireStorageService();
  final TextEditingController _commentController = TextEditingController();
  late int _currentHour;
  Timer? _timer;
  bool _isSending = false;
  bool _isSendButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _syncCurrentHour();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final nowHour = DateTime.now().hour;
      if (nowHour != _currentHour) {
        setState(() {
          _currentHour = nowHour;
        });
      }
    });
  }

  void _syncCurrentHour() {
    _currentHour = DateTime.now().hour;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  //MARK: SendPost
  void _sendPost() async {
    if (_isSending) return;
    final moderationMessage = ContentModeration.rejectionMessage(
      _commentController.text,
    );
    if (moderationMessage != null) {
      WarningSnackBar.showWarning(context, moderationMessage);
      return;
    }
    if (_selectedSlotIndexesByGroupId.isEmpty) {
      WarningSnackBar.showWarning(context, '보낼 슬롯을 먼저 선택해주세요.');
      return;
    }

    final selectedSlotIndexesByGroupId = {
      for (final entry in _selectedSlotIndexesByGroupId.entries)
        entry.key: Set<int>.from(entry.value),
    };
    final now = DateTime.now();
    final String dayKey = _generateDayKey(now);

    try {
      setState(() => _isSending = true);

      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final groups = await _firestoreService.getGroupsByUser(currentUserId);
      final groupsById = {for (final group in groups) group.id: group};
      var createdPostCount = 0;
      var failedPostCount = 0;

      for (final entry in selectedSlotIndexesByGroupId.entries) {
        final group = groupsById[entry.key];
        if (group == null) {
          debugPrint('전송 실패: 선택한 그룹을 찾을 수 없습니다. groupId=${entry.key}');
          failedPostCount++;
          continue;
        }

        final slotOwnerIds = group.effectiveSlotOwnerIds;
        final selectedSlotIndexes = entry.value.toList()..sort();
        if (selectedSlotIndexes.isEmpty) {
          continue;
        }

        for (final slotIndex in selectedSlotIndexes) {
          final isOwnedSlot =
              slotIndex >= 0 &&
              slotIndex < slotOwnerIds.length &&
              slotOwnerIds[slotIndex] == currentUserId;
          if (!isOwnedSlot) {
            debugPrint(
              '전송 실패: 내가 소유한 슬롯이 아닙니다. groupId=${group.id}, slotIndex=$slotIndex',
            );
            failedPostCount++;
            continue;
          }

          final postId = _firestoreService.createPostId(group.id);
          final uploadedVideo = await _fireStorageService.uploadPostVideo(
            filePath: widget.videoPath,
            groupId: group.id,
            postId: postId,
          );

          if (uploadedVideo == null) {
            failedPostCount++;
            continue;
          }

          final newPost = Post(
            id: postId,
            groupId: group.id,
            authorId: currentUserId,
            videoUrl: uploadedVideo.url,
            storagePath: uploadedVideo.storagePath,
            comment: _commentController.text.trim(),
            createdAt: now,
            dayKey: dayKey,
            hourSlot: now.hour,
            slotIndex: slotIndex,
          );

          try {
            await _firestoreService.uploadPost(newPost);
            createdPostCount++;
          } catch (error) {
            await _fireStorageService.deleteVideo(
              videoUrl: uploadedVideo.url,
              storagePath: uploadedVideo.storagePath,
            );
            debugPrint(
              '전송 실패: groupId=${group.id}, slotIndex=$slotIndex, error=$error',
            );
            failedPostCount++;
          }
        }
      }

      if (!mounted) return;

      if (createdPostCount == 0) {
        WarningSnackBar.showWarning(context, '선택한 슬롯에 전송하지 못했습니다.');
        setState(() => _isSending = false);
        return;
      }

      if (failedPostCount > 0) {
        debugPrint('일부 슬롯 전송 실패: $failedPostCount개');
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint("전송 실패: $e");
      if (!mounted) return;
      WarningSnackBar.showWarning(context, '업로드/전송에 실패했습니다.');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _toggleSlot(String groupId, int slotIndex) {
    setState(() {
      final selectedSlotIndexes =
          _selectedSlotIndexesByGroupId[groupId] ?? <int>{};
      if (selectedSlotIndexes.contains(slotIndex)) {
        selectedSlotIndexes.remove(slotIndex);
      } else {
        selectedSlotIndexes.add(slotIndex);
      }

      if (selectedSlotIndexes.isEmpty) {
        _selectedSlotIndexesByGroupId.remove(groupId);
      } else {
        _selectedSlotIndexesByGroupId[groupId] = selectedSlotIndexes;
      }
    });
  }

  void _toggleOwnedSlots(String groupId, List<int> ownedSlotIndexes) {
    if (ownedSlotIndexes.isEmpty) return;

    setState(() {
      final selectedSlotIndexes =
          _selectedSlotIndexesByGroupId[groupId] ?? <int>{};
      final hasSelectedAll = ownedSlotIndexes.every(
        selectedSlotIndexes.contains,
      );

      if (hasSelectedAll) {
        _selectedSlotIndexesByGroupId.remove(groupId);
      } else {
        _selectedSlotIndexesByGroupId[groupId] = ownedSlotIndexes.toSet();
      }
    });
  }

  //MARK: Daykey
  String _generateDayKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  //MARK: ListView
  Widget _buildGroupListView() {
    return FutureBuilder<List<Group>>(
      future: _firestoreService.getGroupsByUser(
        FirebaseAuth.instance.currentUser!.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text("에러가 발생했습니다.", style: TextStyle(color: Colors.white)),
          );
        }

        final groups = snapshot.data ?? [];

        if (groups.isEmpty) {
          return const Center(
            child: Text(
              "참여 중인 그룹이 없습니다.",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final currentUserId = FirebaseAuth.instance.currentUser!.uid;
            final slotOwnerIds = group.effectiveSlotOwnerIds;
            final ownedSlotIndexes = <int>[];
            for (
              var slotIndex = 0;
              slotIndex < slotOwnerIds.length;
              slotIndex++
            ) {
              if (slotOwnerIds[slotIndex] == currentUserId) {
                ownedSlotIndexes.add(slotIndex);
              }
            }
            final selectedSlotIndexes =
                _selectedSlotIndexesByGroupId[group.id] ?? {};
            final selectedCount = selectedSlotIndexes.length;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.black,
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: Image(
                      image: AssetImage('assets/emoji/group1.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                title: Text(
                  group.title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ownedSlotIndexes.isEmpty
                      ? const Text(
                          '내가 들어간 슬롯이 없습니다.',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: ownedSlotIndexes.map((slotIndex) {
                            final isSelected = selectedSlotIndexes.contains(
                              slotIndex,
                            );
                            return FilterChip(
                              label: Text('${slotIndex + 1}번 슬롯'),
                              selected: isSelected,
                              onSelected: (_) =>
                                  _toggleSlot(group.id, slotIndex),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.06,
                              ),
                              selectedColor: Colors.white.withValues(
                                alpha: 0.18,
                              ),
                              checkmarkColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(
                                  alpha: isSelected ? 0.5 : 0.16,
                                ),
                              ),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }).toList(),
                        ),
                ),
                trailing: Text(
                  selectedCount == 0 ? '' : '$selectedCount',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => _toggleOwnedSlots(group.id, ownedSlotIndexes),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(children: [_buildPreviewArea(context), _buildGroupArea()]),
    );
  }

  Widget _buildPreviewArea(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final screenWidth = MediaQuery.sizeOf(context).width;
    const horizontalPadding = 8.0;
    const bottomPadding = 12.0;
    final previewWidth = screenWidth - (horizontalPadding * 2);
    final previewHeight =
        previewWidth / AppLayoutPolicy.previewVideoAspectRatio;
    final previewTop = safeTop;

    return SizedBox(
      height: previewTop + previewHeight + bottomPadding,
      child: Stack(
        children: [
          Positioned(
            top: previewTop,
            left: horizontalPadding,
            right: horizontalPadding,
            height: previewHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ColoredBox(
                color: Colors.black,
                child: VideoPlayerWidget(videoUrl: widget.videoPath),
              ),
            ),
          ),
          Positioned(
            top: previewTop,
            left: horizontalPadding,
            right: horizontalPadding,
            height: previewHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PostCommentOverlay.editable(
                hourText: '${_currentHour.toString().padLeft(2, '0')}:00',
                controller: _commentController,
              ),
            ),
          ),
          Positioned(
            top: safeTop + 6,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: safeTop + 6,
            right: 16,
            child: GestureDetector(
              onTapDown: _isSending
                  ? null
                  : (_) => setState(() => _isSendButtonPressed = true),
              onTapUp: _isSending
                  ? null
                  : (_) => setState(() => _isSendButtonPressed = false),
              onTapCancel: _isSending
                  ? null
                  : () => setState(() => _isSendButtonPressed = false),
              onTap: _isSending ? null : _sendPost,
              child: AnimatedScale(
                scale: _isSendButtonPressed ? 0.9 : 1,
                duration: const Duration(milliseconds: 110),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 110),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: _isSendButtonPressed ? 0.38 : 0.2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupArea() {
    return Expanded(
      flex: 3,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "보낼 슬롯:",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: _buildGroupListView()),
          ],
        ),
      ),
    );
  }
}
