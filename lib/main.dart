import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bababam_app/Helper/ui_presets.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Screen/slot_list_screen.dart';
import 'package:bababam_app/Screen/login_screen.dart';
import 'package:bababam_app/Service/camera_availability_service.dart';
import 'package:bababam_app/Service/firestore_service.dart';
import 'package:bababam_app/Service/push_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  CameraAvailabilityService.preload();

  runApp(const SLOTTApp());
}

class SLOTTApp extends StatefulWidget {
  const SLOTTApp({super.key});

  @override
  State<SLOTTApp> createState() => _SLOTTAppState();
}

class _SLOTTAppState extends State<SLOTTApp> {
  final FireStoreService _firestoreService = FireStoreService();
  final PushNotificationService _pushNotificationService =
      PushNotificationService();
  String? _configuredPushUserId;

  @override
  void dispose() {
    _pushNotificationService.dispose();
    super.dispose();
  }

  void _configurePushNotificationsFor(User? user) {
    final userId = user?.uid;
    if (userId == null) {
      _configuredPushUserId = null;
      return;
    }
    if (_configuredPushUserId == userId) return;

    _configuredPushUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pushNotificationService.configureForCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        _configurePushNotificationsFor(authSnapshot.data);
        final uid = authSnapshot.data?.uid;
        return StreamBuilder<AppUser?>(
          stream: uid == null
              ? Stream<AppUser?>.value(null)
              : _firestoreService.watchUser(uid),
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
        '/home': (context) => const SlotListScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
