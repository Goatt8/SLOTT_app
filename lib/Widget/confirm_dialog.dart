import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isDangerous;
  final String confirmText;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.isDangerous = false,
    this.confirmText = '확인',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        message,
        style: const TextStyle(color: Colors.white70),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmText,
            style: TextStyle(
              color: isDangerous
                  ? Colors.redAccent
                  : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
