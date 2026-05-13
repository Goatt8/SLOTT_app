import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bababam_app/Helper/warning_snackbar.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Service/firestore_service.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String videoPath;

  const VideoPreviewScreen({super.key, required this.videoPath});

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController _controller;
  final Set<String> _selectedGroupIds = {};
  final FireStoreService _firestoreService = FireStoreService();

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath);

    _controller
        .initialize()
        .then((_) {
          print("비디오 초기화 성공!");
          setState(() {
            _controller.play();
            _controller.setLooping(true);
          });
        })
        .catchError((error) {
          print(" 비디오 초기화 실패: $error");
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                Center(
                  child: _controller.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      : const CircularProgressIndicator(),
                ),
                //MARK: Close Button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                //MARK: Send Button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 16,
                  child: GestureDetector(
                    onTap: _sendPost,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                //MARK: test time
                const Center(
                  child: Text(
                    "15:00",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
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
          ),
        ],
      ),
    );
  }

  //MARK: SendPost
  void _sendPost() async {
    if (_selectedGroupIds.isEmpty) return;

    final now = DateTime.now();
    final String dayKey = _generateDayKey(now);

    const String testVideoPath = 'assets/video/test_video.mp4';

    try {
      for (String groupId in _selectedGroupIds) {
        final newPost = Post(
          id: '',
          groupId: groupId,
          authorId: FirebaseAuth.instance.currentUser!.uid,
          videoUrl: testVideoPath,
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
}
