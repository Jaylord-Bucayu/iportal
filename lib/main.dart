import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shop/firebase_options_prod.dart' as prod;
import 'package:shop/firebase_options_staging.dart' as staging;
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/router.dart' as router;
import 'package:shop/theme/app_theme.dart';
import 'package:shop/providers/auth_provider.dart';
import 'http_overrides.dart';

const String env = String.fromEnvironment('ENV', defaultValue: 'production');

Future<void> _backgroundMessage(RemoteMessage message) async {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // No-op on web, sets self-signed-cert bypass on native.
  setHttpOverrides();

  final firebaseOptions = env == 'staging'
      ? staging.DefaultFirebaseOptions.currentPlatform
      : prod.DefaultFirebaseOptions.currentPlatform;

  try {
    await Firebase.initializeApp(
      options: firebaseOptions,
    ).timeout(const Duration(seconds: 10));

    FirebaseMessaging.onBackgroundMessage(_backgroundMessage);
  } catch (e, st) {
    // Don't let a Firebase failure block the app from starting.
    debugPrint('Firebase init failed: $e\n$st');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
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
    final container = ProviderScope.containerOf(
      context,
      listen: false,
    );

    try {
      // Run auth loading and the minimum splash time in parallel,
      // with a timeout so a hanging request can't block the app forever.
      await Future.wait([
        container
            .read(authProvider.notifier)
            .loadFromPrefs()
            .timeout(const Duration(seconds: 10)),
        Future.delayed(const Duration(seconds: 4)),
      ]);
    } catch (e, st) {
      debugPrint('Auth load failed: $e\n$st');
      // Optional: clear bad saved data so the next launch works.
      // await container.read(authProvider.notifier).logout();
    } finally {
      // Always leave the splash screen, even if loading failed.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --------------------------------------------------
    // SPLASH SCREEN
    // --------------------------------------------------
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      );
    }

    // --------------------------------------------------
    // MAIN APP
    // --------------------------------------------------
    return Consumer(
      builder: (context, ref, _) {
        final authUser = ref.watch(authProvider);

        return MaterialApp(
          debugShowCheckedModeBanner: false,

          title: 'DSWD FO2 IPortal',

          theme: AppTheme.lightTheme(context),

          themeMode: ThemeMode.light,

          onGenerateRoute: router.generateRoute,

          initialRoute: authUser != null
              ? entryPointScreenRoute
              : onbordingScreenRoute,

          // --------------------------------------------------
          // RESPONSIVE WEB WIDTH
          // --------------------------------------------------
          builder: (context, child) {
            return Container(
              color: Colors.white,
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================================
// SPLASH SCREEN
// ==========================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

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

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Responsive loader size.
    final loaderSize = screenWidth < 430
        ? screenWidth * 0.7
        : 300.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset(
            'assets/images/splash.gif',
            width: loaderSize,
            height: loaderSize,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}