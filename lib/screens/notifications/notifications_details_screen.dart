import 'package:flutter/material.dart';

class NotificationsDetailsScreen extends StatelessWidget {
  final String title;
  final String body;

  const NotificationsDetailsScreen(
      {super.key, required this.body, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notification Details')),
      body: Padding(padding: EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold
            ),
          ),
          SizedBox(height: 10),
          Text(body)
        ],
      ),
      ),
    );
  }
}
