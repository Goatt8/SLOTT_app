import 'package:flutter/material.dart';
import 'package:bababam_app/Model/group.dart';
import 'dart:math';
import 'package:flutter/services.dart';

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _nameController = TextEditingController();
  late String _randomId;

  int _memberCount = 2;

  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _randomId = _generateGroupId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Bababam'),
        actions: [
          // create Complete Button
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF7C3AED)),
            onPressed: _showConfirmDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('그룹 명 (Title)', style: TextStyle(color: Colors.white70)),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: '그룹명을 입력하세요'),
            ),
            const SizedBox(height: 30),
            const Text(
              '인원 수 선택 (Select Number of People)',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // - Button
                _buildCounterButton(
                  icon: Icons.remove,
                  onPressed: _memberCount > 2
                      ? () => setState(() => _memberCount--)
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      Text(
                        '$_memberCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '명',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // + Button
                _buildCounterButton(
                  icon: Icons.add,
                  onPressed: _memberCount < 10
                      ? () => setState(() => _memberCount++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 50),
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('공유 ID', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 16),
                      Text(
                        _randomId,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.copy,
                          color: Colors.white54,
                          size: 18,
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _randomId));
                          setState(() => _isCopied = true);

                          Future.delayed(
                            const Duration(milliseconds: 1500),
                            () {
                              if (mounted) setState(() => _isCopied = false);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isCopied ? 1.0 : 0.0,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 12.0),
                    child: Text(
                      '클립보드에 복사되었습니다',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: Color(0xFF7C3AED),
      disabledColor: Colors.white10,
      style: IconButton.styleFrom(
        side: BorderSide(
          color: onPressed != null ? Color(0xFF7C3AED) : Colors.white10,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static String _generateGroupId() {
    final random = Random();
    String char = String.fromCharCode(random.nextInt(26) + 65);
    String numbers = random.nextInt(1000000).toString().padLeft(6, '0');

    return '$char$numbers';
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('그룹 생성'),
        content: const Text('그룹을 생성하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: _completeGroupCreation,
            child: const Text('확인', style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }

  void _completeGroupCreation() {
    final newGroup = Group(
      name: _nameController.text.isEmpty ? '새 그룹' : _nameController.text,
      members: List.generate(_memberCount, (i) => '유저${i + 1}'),
    );

    Navigator.pop(context);
    Navigator.pop(context, newGroup);
  }
}
