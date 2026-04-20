import 'package:flutter/material.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Widget/group_list.dart';
import 'package:bababam_app/Widget/add_group_menu.dart';

class GroupListScreen extends StatelessWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Group> groups = [
      Group(name: 'group1', members: ['유저1', '유저2']),
      Group(name: 'group2', members: ['유저2', '유저3', '유저5']),
    ];

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
                builder: (context) => const AddGroupMenu(),
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
