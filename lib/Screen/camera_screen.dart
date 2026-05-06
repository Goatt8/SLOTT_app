import 'package:flutter/material.dart';

class CameraScreen extends StatelessWidget {
  final String groupName;

  const CameraScreen({super.key, required this.groupName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('$groupName 촬영'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text('프리뷰', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('뒤로가기'),
            ),
          ],
        ),
      ),
    );
  }
}
