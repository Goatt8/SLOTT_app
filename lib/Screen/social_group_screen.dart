import 'package:flutter/material.dart';
import 'package:bababam_app/Model/group.dart';

class SocialGroupScreen extends StatefulWidget {
  final Group group;

  const SocialGroupScreen({super.key, required this.group});

  @override
  State<SocialGroupScreen> createState() => _SocialGroupScreenState();
}

class _SocialGroupScreenState extends State<SocialGroupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name)),
      body: Center(child: Text('그룹 ID: ${widget.group.id}')),
    );
  }
}
