import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String videoPath;

  const VideoPreviewScreen({super.key, required this.videoPath});

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController _controller;
  final Set<int> _selectedGroupIndices = {};

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("보낼 그룹 선택"),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
          //MARK: Selct GrouppList
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
                      "전송할 그룹을 선택하세요",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedGroupIndices.contains(
                          index,
                        );
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blueGrey,
                          ),
                          title: Text(
                            "그룹 $index",
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            activeColor: Colors.blue,
                            checkColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedGroupIndices.add(index);
                                } else {
                                  _selectedGroupIndices.remove(index);
                                }
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedGroupIndices.remove(index);
                              } else {
                                _selectedGroupIndices.add(index);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _uploadAndSend(int groupIndex) {
    print("그룹 $groupIndex로 영상 전송 시작!");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
