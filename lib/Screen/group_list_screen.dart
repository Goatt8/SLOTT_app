import 'package:flutter/material.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Widget/group_list.dart';
import 'package:bababam_app/Widget/add_group_menu.dart';
import 'package:bababam_app/Widget/confirm_dialog.dart';
import 'package:bababam_app/Screen/create_group_screen.dart';
import 'package:bababam_app/Screen/social_group_screen.dart';
import 'package:flutter/cupertino.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final List<Group> groups = [
    Group(id: "", name: 'group1', members: ['유저1', '유저2']),
    Group(id: "", name: 'group2', members: ['유저2', '유저3', '유저5']),
  ];

  void _navigateAndAddGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
    );

    if (result != null && result is Group) {
      setState(() {
        groups.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Bababam'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                barrierColor: Colors.black.withValues(alpha: 0.6),
                builder: (context) =>
                    AddGroupMenu(onCreatePressed: _navigateAndAddGroup),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: groups.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final group = groups[index];

          return Dismissible(
            key: Key(
              group.id.isNotEmpty ? group.id : group.name + index.toString(),
            ),

            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (context) => ConfirmDialog(
                      title: '그룹 삭제',
                      message: '${group.name} 그룹을 삭제하시겠습니까?',
                      // 여기서 중요한 점!
                      // 다이얼로그의 확인을 누르면 true를, 취소를 누르면 false를 리턴하게 해야 합니다.
                    ),
                  ) ??
                  false; // 다이얼로그 바깥을 눌러 닫히면 false로 처리
            },
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.redAccent,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              setState(() {
                groups.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${group.name} 그룹이 삭제되었습니다.')),
              );
            },
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SocialGroupScreen(group: group),
                  ),
                );
              },
              child: GroupListItem(group: group),
            ),
          );
        },
      ),
    );
  }
}
