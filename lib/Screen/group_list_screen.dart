import 'package:flutter/material.dart';

class GroupListScreen extends StatelessWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rooms = [
      {'name': 'group1', 'members': 2},
      {'name': 'group2', 'members': 4},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bababam'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})],
      ),
      body: ListView.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];

          return ListTile(
            title: Text(room['name'].toString()),
            subtitle: Text('멤버 ${room['members']}명'),
          );
        },
      ),
    );
  }
}
