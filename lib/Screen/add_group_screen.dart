import 'package:flutter/material.dart';
import 'package:bababam_app/Model/group.dart';
import 'dart:math'; // 랜덤 ID 생성용

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _nameController = TextEditingController();
  int _memberCount = 2;
  final String _randomId = Random().nextInt(999999).toString().padLeft(6, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('새 그룹 만들기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF7C3AED)),
            onPressed: () {
              final newGroup = Group(
                name: _nameController.text.isEmpty
                    ? '새 그룹'
                    : _nameController.text,
                members: List.generate(_memberCount, (i) => '유저${i + 1}'),
              );
              Navigator.pop(context, newGroup);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('그룹 이름', style: TextStyle(color: Colors.white70)),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: '이름을 입력하세요'),
            ),
            const SizedBox(height: 30),
            const Text('최대 인원 선택', style: TextStyle(color: Colors.white70)),
            Slider(
              value: _memberCount.toDouble(),
              min: 2,
              max: 10,
              divisions: 8,
              label: '$_memberCount명',
              onChanged: (val) => setState(() => _memberCount = val.toInt()),
            ),
            const Spacer(),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('공유 ID', style: TextStyle(color: Colors.grey)),
                  Text(
                    _randomId,
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
