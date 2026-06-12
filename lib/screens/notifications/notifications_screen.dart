import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shop/screens/notifications/notifications_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  void firebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    String? token = await messaging.getToken();
    print("FCM TOKEN: , $token");

    //foreground notification
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
                onPressed: () => {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NotificationsDetailsScreen(
                                  body: body, title: title)))
                    },
                child: Text("Next")),
            TextButton(
                onPressed: () => {Navigator.pop(context)},
                child: Text("Cancel"))
          ],
        ),
      );
    });

      //background notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
         final title = message.notification?.title ?? "N/A";
      final body = message.notification?.body ?? "N/A";

      Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsDetailsScreen(body: body, title: title)));
    });

    //in app
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if(message != null){
               final title = message.notification?.title ?? "N/A";
      final body = message.notification?.body ?? "N/A";

      Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsDetailsScreen(body: body, title: title)));
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text("Push notifications",style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20
        ),
        ),
        centerTitle: true,
      ),
    );
  }
}
