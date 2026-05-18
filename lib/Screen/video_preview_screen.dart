import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bababam_app/Helper/ui_presets.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Service/firestore_service.dart';
import 'package:bababam_app/Service/firestorage_service.dart';
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
  final Set<String> _selectedGroupIds = {};
  final FireStoreService _firestoreService = FireStoreService();
  final FireStorageService _fireStorageService = FireStorageService();
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  //MARK: SendPost
  void _sendPost() async {
    if (_isSending) return;
    if (_selectedGroupIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('보낼 그룹을 먼저 선택해주세요.')));
      return;
    }

    final now = DateTime.now();
    final String dayKey = _generateDayKey(now);

    try {
      setState(() => _isSending = true);

      String? uploadedVideoUrl;
      if (widget.uploadedVideoUrlFuture != null) {
        uploadedVideoUrl = await widget.uploadedVideoUrlFuture;
      } else if (widget.videoPath.startsWith('http://') ||
          widget.videoPath.startsWith('https://')) {
        uploadedVideoUrl = widget.videoPath;
      } else {
        uploadedVideoUrl = await _fireStorageService.uploadVideo(
          widget.videoPath,
        );
      }

      if (uploadedVideoUrl == null || uploadedVideoUrl.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('영상 업로드가 완료되지 않았습니다. 잠시 후 다시 시도해주세요.')),
        );
        setState(() => _isSending = false);
        return;
      }

      for (String groupId in _selectedGroupIds) {
        final newPost = Post(
          id: '',
          groupId: groupId,
          authorId: FirebaseAuth.instance.currentUser!.uid,
          videoUrl: uploadedVideoUrl,
          comment: "", //MARK: 미구현
          createdAt: now,
          dayKey: dayKey,
          hourSlot: now.hour,
        );

        await _firestoreService.uploadPost(newPost);
      }

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      print("전송 실패: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('업로드/전송 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _toggleGroup(String groupId) {
    setState(() {
      if (_selectedGroupIds.contains(groupId)) {
        _selectedGroupIds.remove(groupId);
      } else {
        _selectedGroupIds.add(groupId);
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
            final isSelected = _selectedGroupIds.contains(group.id);

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.group, color: Colors.white),
              ),
              title: Text(
                group.title,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: Checkbox(
                value: isSelected,
                activeColor: Colors.blue,
                checkColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                onChanged: (bool? value) => _toggleGroup(group.id),
              ),
              onTap: () => _toggleGroup(group.id),
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
          Center(
            child: Text(
              '${_currentHour.toString().padLeft(2, '0')}:00',
              style: AppTypography.hourOverlay(
                color: Colors.white,
                fontSize: 40,
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
                "보낼 로그방:",
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
