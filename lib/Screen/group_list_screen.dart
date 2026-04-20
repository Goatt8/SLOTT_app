import 'package:flutter/material.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Widget/group_list.dart';
import 'package:bababam_app/Widget/add_group_menu.dart';
import 'package:bababam_app/Screen/add_group_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final List<Group> groups = [
    Group(name: 'group1', members: ['유저1', '유저2']),
    Group(name: 'group2', members: ['유저2', '유저3', '유저5']),
  ];

  void _navigateAndAddGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGroupScreen()),
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
          return GroupListItem(group: groups[index]);
        },
      ),
    );
  }
}
