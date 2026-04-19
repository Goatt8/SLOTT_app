import 'package:flutter/material.dart';
import 'package:bababam_app/Screen/group_list_screen.dart';

void main() {
  runApp(const BababamApp());
}

class BababamApp extends StatelessWidget {
  const BababamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bababam',
      theme: ThemeData.dark(),
      home: const GroupListScreen(),
    );
  }
}
