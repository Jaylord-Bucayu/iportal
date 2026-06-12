import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shop/components/Banner/S/banner_s_style_5.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';

import 'components/most_popular.dart';
import 'components/offer_carousel_and_categories.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void firebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

// Request permissions for iOS and Android 13+
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
  }


    String? token = await messaging.getToken();
    print("FCM TOKEN: $token");

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
            style: TextStyle(overflow: TextOverflow.ellipsis),
          ),
          actions: [
            TextButton(
              onPressed: () {
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
              child: const Text("Next"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
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
    firebaseMessaging();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: OffersCarouselAndCategories()),
            // const SliverToBoxAdapter(child: MostPopular()),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // const SizedBox(height: defaultPadding * 1.5),
                  // const SizedBox(height: defaultPadding / 4),
                  // BannerSStyle5(
                  //   title: "Leave Management",
                  //   subtitle: "DSWD IPORTAL",
                  //   bottomText: "Application".toUpperCase(),
                  //   press: () {
                  //     // Navigator.pushNamed(context, onSaleScreenRoute);
                  //   },
                  // ),
                  // const SizedBox(height: defaultPadding / 4),
            
                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
