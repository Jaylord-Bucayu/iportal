import 'package:flutter/material.dart';
import 'package:shop/models/contact_model.dart';
import 'package:url_launcher/url_launcher.dart';  // Import url_launcher package

class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Appbar search
          // Container(
          //   margin: const EdgeInsets.only(bottom: 16.0),
          //   padding: const EdgeInsets.fromLTRB(
          //     16.0,
          //     0,
          //     16.0,
          //     0,
          //   ),
          //   color: Colors.white,
          //   child: Form(
          //     child: TextFormField(
          //       autofocus: true,
          //       textInputAction: TextInputAction.search,
          //       onChanged: (value) {
          //         // search functionality
          //       },
          //       decoration: InputDecoration(
          //         fillColor: Colors.white,
          //         prefixIcon: Icon(
          //           Icons.search,
          //           color: const Color(0xFF1D1D35).withOpacity(0.64),
          //         ),
          //         hintText: "Search",
          //         hintStyle: TextStyle(
          //           color: const Color(0xFF1D1D35).withOpacity(0.64),
          //         ),
          //         filled: true,
          //         contentPadding: const EdgeInsets.symmetric(
          //             horizontal: 16.0 * 1.5, vertical: 16.0),
          //         border: const OutlineInputBorder(
          //           borderSide: BorderSide.none,
          //           borderRadius: BorderRadius.all(Radius.circular(50)),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          
          Expanded(
            child: SafeArea(
              child: ListView(
                children: [
                  // Generate CallHistoryCard widgets with phone number
                  ...List.generate(
                    Contact.getDummyContacts().length,
                    (index) => CallHistoryCard(
                      name: Contact.getDummyContacts()[index].name,
                      image: Contact.getDummyContacts()[index].image,
                      time: "CPIII",
                      isActive: false,
                      isOutgoingCall: index.isOdd,
                      isVideoCall: index.isEven,
                      mobileNo: Contact.getDummyContacts()[index].mobileNo,  // Pass the mobileNo
                      press: () {
                        // Trigger the phone call when the item is tapped
                        _makePhoneCall(Contact.getDummyContacts()[index].mobileNo);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to make a phone call
  Future<void> _makePhoneCall(String mobileNo) async {
    final Uri url = Uri(scheme: 'tel', path: mobileNo);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}

class CallHistoryCard extends StatelessWidget {
  const CallHistoryCard({
    super.key,
    required this.name,
    required this.time,
    required this.isActive,
    required this.isVideoCall,
    required this.isOutgoingCall,
    required this.image,
    required this.press,
    required this.mobileNo,  // Add the mobileNo parameter
  });

  final String name, time, image, mobileNo;  // Add mobileNo as a parameter
  final bool isActive, isVideoCall, isOutgoingCall;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 16.0 / 2,
      ),
      onTap: null,  // Trigger the call when tapped
      leading: CircleAvatarWithActiveIndicator(
        image: image,
        isActive: isActive,
        radius: 28,
      ),
      title: Text(name),
      subtitle: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0 / 2),
        child: Row(
          children: [
            // Icon(
            //   isOutgoingCall ? Icons.north_east : Icons.south_west,
            //   size: 16,
            //   color: isOutgoingCall
            //       ? Theme.of(context).primaryColor
            //       : const Color(0xFFF03738),
            // ),
            // const SizedBox(width: 16.0 / 2),
            Text(
              time,
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .color!
                    .withOpacity(0.64),
              ),
            ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Call icon
          IconButton(
            icon: Icon(
              Icons.call,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              // Trigger the phone call when the call icon is clicked
              _makePhoneCall(mobileNo);
            },
          ),
          // SMS icon
          IconButton(
            icon: Icon(
              Icons.message,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              // Trigger the SMS when the message icon is clicked
              _sendSMS(mobileNo);
            },
          ),
        ],
      ),
    );
  }

  // Function to make a phone call
  Future<void> _makePhoneCall(String mobileNo) async {
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

class CircleAvatarWithActiveIndicator extends StatelessWidget {
  const CircleAvatarWithActiveIndicator({
    super.key,
    this.image,
    this.radius = 24,
    this.isActive,
  });

  final String? image;
  final double? radius;
  final bool? isActive;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(image!),
        ),
        if (isActive!)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              height: 16,
              width: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF00BF6D),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor, width: 3),
              ),
            ),
          )
      ],
    );
  }
}
