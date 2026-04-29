import 'package:flutter/material.dart';
import 'package:bababam_app/Model/user.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Model/mock_data.dart';
import 'package:bababam_app/Widget/member_post_card.dart';

class SocialGroupScreen extends StatefulWidget {
  final Group group;

  const SocialGroupScreen({super.key, required this.group});

  @override
  State<SocialGroupScreen> createState() => _SocialGroupScreenState();
}

class _SocialGroupScreenState extends State<SocialGroupScreen> {
  @override
  Widget build(BuildContext context) {
    final Group currentGroup = widget.group;
    final List<User> members = allTestUsers
        .where((user) => currentGroup.memberIds.contains(user.id))
        .toList();
    final int count = members.length;

    return Scaffold(
      appBar: AppBar(title: Text(currentGroup.title)),
      body: SafeArea(
        child: count <= 6
            ? _buildVerticalLayout(members)
            : _buildGridLayout(members),
      ),
    );
  }

  Widget _buildVerticalLayout(List<User> members) {
    return Column(
      children: members
          .map((user) => Expanded(child: MemberPostCard(member: user)))
          .toList(),
    );
  }

  Widget _buildGridLayout(List<User> members) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.5,
      ),
      itemCount: members.length,
      itemBuilder: (context, index) {
        return MemberPostCard(member: members[index]);
      },
    );
  }
}
