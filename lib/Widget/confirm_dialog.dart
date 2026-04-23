import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;

  const ConfirmDialog({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: Text(message, style: const TextStyle(color: Colors.white70)),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        // cancel
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('취소', style: TextStyle(color: Colors.grey)),
        ),
        // ok
        TextButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: const Text('확인', style: TextStyle(color: Color(0xFF7C3AED))),
        ),
      ],
    );
  }
}
