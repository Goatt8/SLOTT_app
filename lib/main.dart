import 'package:flutter/material.dart';
import 'package:bababam_app/Screen/group_list_screen.dart';
import 'package:bababam_app/Screen/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const BababamApp());
}

class BababamApp extends StatelessWidget {
  const BababamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bababam',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF7C3AED),
          secondary: Color(0xFFFF2D55),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
