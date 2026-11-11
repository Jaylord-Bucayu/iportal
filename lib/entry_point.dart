import 'dart:convert';
import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/screens/directory/views/directory_screen.dart';
import 'package:shop/services/api_config.dart';

/// Height of the glass nav bar (not counting the bottom safe-area inset).
/// Add this + the bottom inset as bottom padding in your scrollable pages
/// so the last item isn't hidden behind the bar.
const double glassNavBarHeight = 64;

class EntryPoint extends ConsumerStatefulWidget {
  const EntryPoint({super.key});

  @override
  ConsumerState<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends ConsumerState<EntryPoint> {
  final List _pages = [
    const HomeScreen(),
    const DirectoryHomeScreen(),
    const ProfileScreen(),
  ];
  int _currentIndex = 0;
  int _unreadNotifications = 0;

  Future<void> _saveFcmToken(String token, String staffId) async {
    try {
      final String device;

      if (kIsWeb) {
        device = 'web';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        device = 'android';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        device = 'ios';
      } else {
        device = 'unknown';
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.fcmSaveUrl}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'device': device,
          'user_id': staffId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('FCM token saved successfully');
      } else {
        print(
            'Failed to save FCM token: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  void _initFirebaseMessaging() async {
    final auth = ref.read(authProvider);
    final staffId = auth?.staffId?.toString() ?? '';

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
      return; // No point getting token if permission denied
    }

    // Get token and save to API
    final String? token = await messaging.getToken();
    print("FCM TOKEN: $token");

    if (token != null && staffId.isNotEmpty) {
      await _saveFcmToken(token, staffId);
    }

    // Foreground notification — no popup, just badge the bell icon
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;
      setState(() {
        _unreadNotifications++;
      });
    });

    // App opened from background notification (user tapped the tray notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final title = message.notification?.title ?? "N/A";
      final body = message.notification?.body ?? "N/A";

      if (mounted) setState(() => _unreadNotifications = 0);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              NotificationsDetailsScreen(body: body, title: title),
        ),
      );
    });

    // App opened from terminated state (cold start via tapped notification)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final title = message.notification?.title ?? "N/A";
        final body = message.notification?.body ?? "N/A";

        if (mounted) setState(() => _unreadNotifications = 0);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                NotificationsDetailsScreen(body: body, title: title),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final staffId = auth?.staffId?.toString() ?? '';
    final imageUrl =
        'https://fo2-staff-search.dswd.gov.ph/images/$staffId.jpg';

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const SizedBox(),
        leadingWidth: 0,
        centerTitle: false,
        toolbarHeight: 80,
        title: Image.asset(
          "assets/images/app-logo.png",
          height: 36,
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _unreadNotifications > 0,
              label: Text(
                _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                style: const TextStyle(fontSize: 10),
              ),
              backgroundColor: const Color(0xFFE2420E),
              child: const Icon(Icons.notifications_none_rounded),
            ),
            iconSize: 26,
            tooltip: 'Notifications',
            onPressed: () {
              setState(() => _unreadNotifications = 0);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // ── MAIN PAGE (scrolls behind the glass bar) ──
          Positioned.fill(
            child: PageTransitionSwitcher(
              duration: defaultDuration,
              transitionBuilder: (child, animation, secondAnimation) {
                return FadeThroughTransition(
                  animation: animation,
                  secondaryAnimation: secondAnimation,
                  child: child,
                );
              },
              child: _pages[_currentIndex],
            ),
          ),

          // ── GLASS NAVIGATION BAR ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _GlassNavBar(
              currentIndex: _currentIndex,
              imageUrl: imageUrl,
              onTap: (index) {
                if (index != _currentIndex) {
                  setState(() => _currentIndex = index);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width frosted-glass bottom navigation bar.
/// Icon on top, label underneath. The active tab uses [_activeColor].
/// Content scrolling behind it is blurred.
class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.imageUrl,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final String imageUrl;

  static const Color _activeColor = primaryColor; // from constants.dart
  static const Color _inactiveColor = Color(0xFF3A3F55);

  static const List<_NavItem> _items = [
    _NavItem(icon: "assets/icons/Home.svg", label: "Home"),
    _NavItem(icon: "assets/icons/Location.svg", label: "Offices"),
    _NavItem(icon: "assets/icons/User.svg", label: "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: glassNavBarHeight + bottomInset,
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.70),
            border: Border(
              top: BorderSide(color: Colors.black.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final bool isActive = index == currentIndex;
              final bool isProfile = index == _items.length - 1;
              final Color color = isActive ? _activeColor : _inactiveColor;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(index),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      width: 56,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive
                            ? _activeColor.withOpacity(0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: isProfile
                          ? _Avatar(
                        imageUrl: imageUrl,
                        borderColor: isActive
                            ? _activeColor
                            : Colors.transparent,
                      )
                          : SvgPicture.asset(
                        _items[index].icon,
                        height: 24,
                        width: 24,
                        colorFilter:
                        ColorFilter.mode(color, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl, required this.borderColor});

  final String imageUrl;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.person, size: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final String icon;
  final String label;
}