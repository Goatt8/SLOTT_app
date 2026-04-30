import 'package:flutter/material.dart';
import 'package:bababam_app/Model/post.dart';
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
  int? _selectedHour;

  @override
  Widget build(BuildContext context) {
    final Group currentGroup = widget.group;
    final List<User> members = allTestUsers
        .where((user) => currentGroup.memberIds.contains(user.id))
        .toList();
    final List<Post> groupPosts = testPosts
        .where((post) => post.groupId == currentGroup.id)
        .toList();
    final List<int> availableHours = groupPosts
        .map((post) => post.hourSlot)
        .toSet()
        .toList()
      ..sort();
    final int? selectedHour = _resolveSelectedHour(availableHours);
    final List<Post> selectedPosts = selectedHour == null
        ? const []
        : groupPosts
              .where((post) => post.hourSlot == selectedHour)
              .toList();
    final int count = members.length;

    return Scaffold(
      appBar: AppBar(title: Text(currentGroup.title)),
      body: SafeArea(
        child: Column(
          children: [
            _buildHourSelector(availableHours),
            Expanded(
              child: count <= 6
                  ? _buildVerticalLayout(members, selectedPosts)
                  : _buildGridLayout(members, selectedPosts),
            ),
          ],
        ),
      ),
    );
  }

  int? _resolveSelectedHour(List<int> availableHours) {
    if (availableHours.isEmpty) {
      return null;
    }

    if (_selectedHour == null || !availableHours.contains(_selectedHour)) {
      _selectedHour = availableHours.first;
    }

    return _selectedHour;
  }

  Widget _buildHourSelector(List<int> availableHours) {
    if (availableHours.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '아직 올라온 시간대가 없어요',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: availableHours.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final hour = availableHours[index];
          final bool isSelected = hour == _selectedHour;

          return ChoiceChip(
            label: Text('${hour.toString().padLeft(2, '0')}:00'),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _selectedHour = hour;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildVerticalLayout(List<User> members, List<Post> selectedPosts) {
    return Column(
      children: members
          .map(
            (user) => Expanded(
              child: MemberPostCard(
                member: user,
                post: _findPostForUser(selectedPosts, user.id),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGridLayout(List<User> members, List<Post> selectedPosts) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.5,
      ),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final user = members[index];
        return MemberPostCard(
          member: user,
          post: _findPostForUser(selectedPosts, user.id),
        );
      },
    );
  }

  Post? _findPostForUser(List<Post> posts, String userId) {
    for (final post in posts) {
      if (post.authorId == userId) {
        return post;
      }
    }
    return null;
  }
}
