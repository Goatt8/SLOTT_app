import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bababam_app/Helper/ui_presets.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Screen/group_list_screen.dart';
import 'package:bababam_app/Screen/login_screen.dart';
import 'package:bababam_app/Service/firestore_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const BababamApp());
}

class BababamApp extends StatefulWidget {
  const BababamApp({super.key});

  @override
  State<BababamApp> createState() => _BababamAppState();
}

class _BababamAppState extends State<BababamApp> {
  final FireStoreService _firestoreService = FireStoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final uid = authSnapshot.data?.uid;
        if (uid == null) {
          return _buildMaterialApp(AppAccentColor.defaultColor);
        }

        return StreamBuilder<AppUser?>(
          stream: _firestoreService.watchUser(uid),
          builder: (context, userSnapshot) {
            final accentColor = AppAccentColor.fromColorId(
              userSnapshot.data?.colorId,
            );
            return _buildMaterialApp(accentColor);
          },
        );
      },
    );
  }

  Widget _buildMaterialApp(Color accentColor) {
    return MaterialApp(
      title: 'SLOTT',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: accentColor,
          secondary: Color(0xFFFF2D55),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: accentColor),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(color: accentColor),
      ),
      routes: {
        '/home': (context) => const GroupListScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
