import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectoryDetailsScreen extends StatelessWidget {

  final List<Map<String, dynamic>> participantList = [
    {
      "name": "Abigail Flores",
      "role": "HR Specialist",
      "initial": "A",
      "phone": "1234567890",
    },
    {
      "name": "Asher Morris",
      "role": "Senior Recruiter",
      "initial": "A",
      "phone": "9876543210",
    },
    {
      "name": "Aurora Johnson",
      "role": "HR Coordinator",
      "initial": "A",
      "phone": "5556667777",
    },
    {
      "name": "Bennett Reed",
      "role": "Recruiter",
      "initial": "B",
      "phone": "2223334444",
    },
    {
      "name": "Blair Hopkins",
      "role": "HR Manager",
      "initial": "B",
      "phone": "4445556666",
    },
    {
      "name": "Brock Salazar",
      "role": "HR Business Partner",
      "initial": "B",
      "phone": "1112223333",
    },
  ];

   DirectoryDetailsScreen({super.key});

  // DirectoryDetailsScreen({
  //   Key? key,
  //   required this.groupName,
  //   required this.participants,
  // }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Lists',style: TextStyle(color: Colors.white)),
        
        backgroundColor: Colors.primaries[4],
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   "Directories",
            //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            // ),
            // Text(
            //   "23 participants",
            //   style: TextStyle(color: Colors.grey),
            // ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: participantList.length,
                itemBuilder: (context, index) {
                  final participant = participantList[index];
                  final showInitial = index == 0 ||
                      participant['initial'] !=
                          participantList[index - 1]['initial'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showInitial)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            participant['initial'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.primaries[4],
                          child: Text(
                            participant['name'][0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(participant['name']),
                        subtitle: Text(participant['role']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.call, color: Colors.primaries[1]),
                              onPressed: () {
                                _makeCall(participant['phone']);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.message, color: Colors.primaries[4]),
                              onPressed: () {
                                _sendSMS(participant['phone']);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

 // Function to make a phone call
  Future<void> _makeCall(String mobileNo) async {
    final Uri url = Uri(scheme: 'tel', path: mobileNo);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  // Function to send SMS
  Future<void> _sendSMS(String mobileNo) async {
    final Uri url = Uri(scheme: 'sms', path: mobileNo);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch SMS');
    }
  }
}
