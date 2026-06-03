import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Service/firestore_service.dart';
import 'package:bababam_app/Widget/confirm_dialog.dart';
import 'package:bababam_app/Helper/warning_snackbar.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  late String _randomId;

  int _memberCount = 2;

  bool _isCopied = false;
  bool _isCreating = false;
  final FireStoreService _firestoreService = FireStoreService();

  @override
  void initState() {
    super.initState();
    _randomId = _generateGroupId();
  }

  Widget _buildCounterButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: accentColor,
      disabledColor: Colors.white10,
      style: IconButton.styleFrom(
        side: BorderSide(
          color: onPressed != null ? accentColor : Colors.white10,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  //MARK: Generate Id Key
  static String _generateGroupId() {
    final random = Random();
    final letters = List.generate(
      2,
      (_) => String.fromCharCode(random.nextInt(26) + 65),
    ).join();
    final numbers = random.nextInt(10000).toString().padLeft(4, '0');

    return '$letters$numbers';
  }

  //MARK: ShowDialog
  void _showConfirmDialog() async {
    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          const ConfirmDialog(title: '그룹 생성', message: '그룹을 생성하시겠습니까?'),
    );
    if (isConfirmed == true) {
      _completeGroupCreation();
    }
  }

  //MARK: Create Group
  Future<void> _completeGroupCreation() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final newGroup = Group(
      id: _randomId,
      title: _nameController.text.isEmpty ? '새 그룹' : _nameController.text,
      memberIds: [currentUser.uid],
      ownerId: currentUser.uid,
      memberCount: _memberCount,
    );

    setState(() => _isCreating = true);

    try {
      await _firestoreService.createGroup(newGroup);

      if (!mounted) return;
      Navigator.pop(context, newGroup);
    } catch (error) {
      if (!mounted) return;
      WarningSnackBar.showWarning(context, "그룹생성에 실패했습니다.");
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Bababam'),
        actions: [
          //MARK: Create Complete Button
          IconButton(
            icon: Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _isCreating ? null : _showConfirmDialog,
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
}
