import 'dart:convert';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/providers/auth_provider.dart';

class EntryPoint extends ConsumerStatefulWidget {
  const EntryPoint({super.key});

  @override
  ConsumerState<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends ConsumerState<EntryPoint> {
  final List _pages = [
    const HomeScreen(),
    DirectoryHomeScreen(),
    const ProfileScreen(),
  ];
  int _currentIndex = 0;

  Future<void> _saveFcmToken(String token, String staffId) async {
    try {
      final device = Platform.isAndroid ? 'android' : 'ios';

      final response = await http.post(
        Uri.parse('http://172.31.16.69/api/v1/notifications/save-fcm'),
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
        print('Failed to save FCM token: ${response.statusCode} ${response.body}');
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
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
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

    // Foreground notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? "N/A";
      final body = message.notification?.body ?? "N/A";

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(
            body,
            maxLines: 1,
            style: const TextStyle(overflow: TextOverflow.ellipsis),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsDetailsScreen(
                      body: body,
                      title: title,
                    ),
                  ),
                );
              },
              child: const Text("View"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Dismiss"),
            ),
          ],
        ),
      );
    });

    // App opened from background notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final title = message.notification?.title ?? "N/A";
      final body = message.notification?.body ?? "N/A";

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              NotificationsDetailsScreen(body: body, title: title),
        ),
      );
    });

    // App opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final title = message.notification?.title ?? "N/A";
        final body = message.notification?.body ?? "N/A";

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
    final fullName = auth?.fullName ?? 'User';
    final imageUrl =
        'https://fo2-staff-search.dswd.gov.ph/images/$staffId.jpg';

    SvgPicture svgIcon(String src, {Color? color}) {
      return SvgPicture.asset(
        src,
        height: 24,
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const SizedBox(),
        leadingWidth: 0,
        centerTitle: false,
        toolbarHeight: 80,
        title: Row(
          children: [
            ClipOval(
              child: Image.network(
                imageUrl,
                height: 45,
                width: 45,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 45,
                    width: 45,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 26,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hi, $fullName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Welcome to DSWD FO2 IPORTAL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: PageTransitionSwitcher(
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
      bottomNavigationBar: Container(
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index != _currentIndex) {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedItemColor: primaryColor,
          items: [
            BottomNavigationBarItem(
              icon: svgIcon("assets/icons/Home.svg"),
              activeIcon: svgIcon("assets/icons/Home.svg", color: primaryColor),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: svgIcon("assets/icons/Location.svg"),
              activeIcon:
              svgIcon("assets/icons/Location.svg", color: primaryColor),
              label: "Directories",
            ),
            BottomNavigationBarItem(
              icon: svgIcon("assets/icons/User.svg"),
              activeIcon: svgIcon("assets/icons/User.svg", color: primaryColor),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}