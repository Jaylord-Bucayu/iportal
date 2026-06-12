import 'dart:io'; // 👈 Add this for HttpOverrides

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shop/firebase_options.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/router.dart' as router;
import 'package:shop/theme/app_theme.dart';
import 'package:shop/providers/auth_provider.dart';

Future<void> _backgroundMessage(RemoteMessage message) async {}

/// 👇 Add this class to allow self-signed SSL certs
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_backgroundMessage);
  FlutterGemma.initialize(); // ← required before anything else

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuth();
  }

  Future<void> _loadAuth() async {
    final container = ProviderScope.containerOf(context, listen: false);
    await container.read(authProvider.notifier).loadFromPrefs();

    // Always show splash for 4 seconds
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show splash screen
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      );
    }

    return Consumer(
      builder: (context, ref, _) {
        final authUser = ref.watch(authProvider);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'DSWD FOII IPortal',
          theme: AppTheme.lightTheme(context),
          themeMode: ThemeMode.light,
          onGenerateRoute: router.generateRoute,
          initialRoute: authUser != null
              ? entryPointScreenRoute
              : onbordingScreenRoute,
        );
      },
    );
  }
}

/// 👇 Splash Screen with Fade-in PNG and 4 seconds display
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Fade-in duration: 2 seconds
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset(
            'assets/images/dswd-pilipinas.png', // ✅ your PNG
            width: 200,
            height: 200,
          ),
          
        ),
      ),
    );
  }
}