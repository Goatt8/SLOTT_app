import 'package:bababam_app/Model/user.dart';
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

// Test
final user1 = User(id: '', name: 'user1');
final user2 = User(id: '', name: 'user2');

final List<Group> groups = [
  Group(id: "g1", title: 'group1', members: [user1, user2]),
];

class _GroupListScreenState extends State<GroupListScreen> {
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
              group.id.isNotEmpty ? group.id : group.title + index.toString(),
            ),

            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (context) => ConfirmDialog(
                      title: '그룹 삭제',
                      message: '${group.title} 그룹을 삭제하시겠습니까?',
                    ),
                  ) ??
                  false;
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
                SnackBar(content: Text('${group.title} 그룹이 삭제되었습니다.')),
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
