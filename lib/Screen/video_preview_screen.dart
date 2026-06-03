import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bababam_app/Helper/ui_presets.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Helper/warning_snackbar.dart';
import 'package:bababam_app/Service/firestore_service.dart';
import 'package:bababam_app/Service/firestorage_service.dart';
import 'package:bababam_app/Widget/post_comment_overlay.dart';
import 'package:bababam_app/Widget/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String videoPath;
  final Future<String?>? uploadedVideoUrlFuture;

  const VideoPreviewScreen({
    super.key,
    required this.videoPath,
    this.uploadedVideoUrlFuture,
  });

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

  bool _isRemoteVideo(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Future<String?> _uploadVideoForPost() async {
    if (_isRemoteVideo(widget.videoPath)) {
      return widget.videoPath;
    }

    if (widget.uploadedVideoUrlFuture != null) {
      final uploadedUrl = await widget.uploadedVideoUrlFuture;
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        return uploadedUrl;
      }
    }

    return _fireStorageService.uploadVideo(widget.videoPath);
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
    if (_selectedSlotIndexesByGroupId.isEmpty) {
      WarningSnackBar.showWarning(context, '보낼 슬롯을 먼저 선택해주세요.');
      return;
    }

    final now = DateTime.now();
    final String dayKey = _generateDayKey(now);

    try {
      setState(() => _isSending = true);

      final uploadedVideoUrl = await _uploadVideoForPost();

      if (uploadedVideoUrl == null || uploadedVideoUrl.isEmpty) {
        if (!mounted) return;
        WarningSnackBar.showWarning(
          context,
          '영상 업로드가 완료되지 않았습니다. 잠시 후 다시 시도해주세요.',
        );
        setState(() => _isSending = false);
        return;
      }

      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final groups = await _firestoreService.getGroupsByUser(currentUserId);
      final selectedGroups = groups.where(
        (group) => _selectedSlotIndexesByGroupId.containsKey(group.id),
      );
      var createdPostCount = 0;

      for (final group in selectedGroups) {
        final slotOwnerIds = group.effectiveSlotOwnerIds;
        final selectedSlotIndexes =
            _selectedSlotIndexesByGroupId[group.id] ?? {};
        if (selectedSlotIndexes.isEmpty) {
          continue;
        }

        for (final slotIndex in selectedSlotIndexes) {
          final isOwnedSlot =
              slotIndex >= 0 &&
              slotIndex < slotOwnerIds.length &&
              slotOwnerIds[slotIndex] == currentUserId;
          if (!isOwnedSlot) continue;

          final newPost = Post(
            id: '',
            groupId: group.id,
            authorId: currentUserId,
            videoUrl: uploadedVideoUrl,
            comment: _commentController.text.trim(),
            createdAt: now,
            dayKey: dayKey,
            hourSlot: now.hour,
            slotIndex: slotIndex,
          );

          await _firestoreService.uploadPost(newPost);
          createdPostCount++;
        }
      }

      if (!mounted) return;

      if (createdPostCount == 0) {
        WarningSnackBar.showWarning(context, '내가 들어간 슬롯만 선택할 수 있습니다.');
        setState(() => _isSending = false);
        return;
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
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.group, color: Colors.white),
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
                              label: Text('${slotIndex + 1}번 칸'),
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
    return Expanded(
      flex: 2,
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: AppLayoutPolicy.previewVideoAspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.black,
                  child: VideoPlayerWidget(videoUrl: widget.videoPath),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: GestureDetector(
              onTap: _isSending ? null : _sendPost,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
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
          Positioned.fill(
            child: PostCommentOverlay.editable(
              hourText: '${_currentHour.toString().padLeft(2, '0')}:00',
              controller: _commentController,
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
