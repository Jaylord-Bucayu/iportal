import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

class DirectoryHomeScreen extends StatefulWidget {
  const DirectoryHomeScreen({super.key});

  @override
  State<DirectoryHomeScreen> createState() => _DirectoryHomeScreenState();
}

class _DirectoryHomeScreenState extends State<DirectoryHomeScreen> {
  final List<Map<String, dynamic>> teams = [
    {
      'name': 'Regional Office',
      'lat': "17.655506",
      'long': "121.745756",
      "link": "https://maps.app.goo.gl/jooG5ZvADxNUC6in8"
    },
    {
      'name': 'Provincial Operations Office Cagayan',
      'lat': "17.622649",
      'long': "121.720944",
      "link": "https://maps.app.goo.gl/jooG5ZvADxNUC6in8"
    },
    {
      'name': 'Provincial Operations Office Isabela',
      'lat': "17.1032169",
      'long': "121.8629681",
      "link": "https://maps.app.goo.gl/jooG5ZvADxNUC6in8"
    },
  ];

  String searchQuery = "";

  Future<void> _handleShare(String type, String message) async {
    final encodedMessage = Uri.encodeComponent(message);

    switch (type) {
      case "messenger":
        final uri = Uri.parse("fb-messenger://share?link=$encodedMessage");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          print("Messenger not installed");
        }
        break;

      case "whatsapp":
        final uri = Uri.parse("whatsapp://send?text=$encodedMessage");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          print("WhatsApp not installed");
        }
        break;

      case "email":
        final uri =
            Uri.parse("mailto:?subject=Check this out&body=$encodedMessage");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          print("No email app found");
        }
        break;

      case "sms":
        final uri = Uri.parse("sms:?body=$encodedMessage");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          print("No SMS app found");
        }
        break;

      case "telegram":
        final uri = Uri.parse("tg://msg?text=$encodedMessage");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          print("Telegram not installed");
        }
        break;

      case "viber":
        final uri = Uri.parse("viber://forward?text=$encodedMessage");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          print("Viber not installed");
        }
        break;

      case "others":
      case "more":
        Share.share(message);
        break;
      default:
        Share.share(message);
        break;
    }
  }

  // 📌 Bottom sheet
  void _showBottomSheet(BuildContext context, Map<String, dynamic> team) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        final shareOptions = [
          {
            "icon": "assets/icons/messenger.svg",
            "label": "Messenger",
            "type": "messenger"
          },
          {"icon": "assets/icons/gmail.svg", "label": "Gmail", "type": "email"},
          {
            "icon": "assets/icons/whatsapp.svg",
            "label": "WhatsApp",
            "type": "whatsapp"
          },
          {"icon": "assets/icons/Message.svg", "label": "SMS", "type": "sms"},
          {
            "icon": "assets/icons/telegram.svg",
            "label": "Telegram",
            "type": "telegram"
          },
          {"icon": "assets/icons/viber.svg", "label": "Viber", "type": "viber"},
          {"icon": "assets/icons/DotsH.svg", "label": "More", "type": "more"},
        ];

        final locationOptions = [
          {"icon": "assets/icons/map.svg", "label": "Maps"}
        ];

        final shareText =
            "Check out ${team['name']} location: ${team['link']}";

        return SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                // First title
                const Text(
                  "Share via",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // First row
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: shareOptions.length,
                    itemBuilder: (context, index) {
                      final opt = shareOptions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: _buildOption(opt["icon"]!, opt["label"]!, () {
                          Navigator.pop(context);
                          _handleShare(
                              opt["type"]!, shareText); // ✅ pass type
                        }),
                      );
                    },
                  ),
                ),

                // Second title
                const Text(
                  "Others",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),

                // Second row
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: locationOptions.length,
                    itemBuilder: (context, index) {
                      final opt = locationOptions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: _buildOption(opt["icon"]!, opt["label"]!,
                            () async {
                          Navigator.pop(context);

                          final url = team['link'];
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url),
                                mode: LaunchMode.externalApplication);
                          }
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOption(String svgPath, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            svgPath,
            width: 40,
            height: 40,
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  final filteredTeams = teams
      .where((team) =>
          team['name'].toString().toLowerCase().contains(searchQuery))
      .toList();

  final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

  return GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    behavior: HitTestBehavior.translucent,
    child: Scaffold(
      backgroundColor: Colors.grey[100],
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // 🔳 Header + Search Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // ✅ Hide this whole header if keyboard is open
                if (!isKeyboardOpen)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Directories',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.0,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'List of MOO, Offices and Provinces locations.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        child: Image.asset(
                          "assets/images/directories.png",
                          width: 160,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // ✅ Search bar (always visible at top)
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search office...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ],
            ),
          ),

          // ✅ Team list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: filteredTeams.length,
              itemBuilder: (context, index) {
                final team = filteredTeams[index];

                return GestureDetector(
                  onTap: () => _showBottomSheet(context, team),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            team['name'] ?? 'Unknown Team',
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
}
