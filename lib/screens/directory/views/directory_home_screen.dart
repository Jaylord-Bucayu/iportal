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
  static final Color _primaryColor = Colors.primaries[4]; // indigo
  static final Color _primaryDark = Colors.primaries[4].shade700;

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

  static final List<Map<String, String>> _shareOptions = [
    {"icon": "assets/icons/messenger.svg", "label": "Messenger", "type": "messenger"},
    {"icon": "assets/icons/gmail.svg", "label": "Gmail", "type": "email"},
    {"icon": "assets/icons/whatsapp.svg", "label": "WhatsApp", "type": "whatsapp"},
    {"icon": "assets/icons/Message.svg", "label": "SMS", "type": "sms"},
    {"icon": "assets/icons/telegram.svg", "label": "Telegram", "type": "telegram"},
    {"icon": "assets/icons/viber.svg", "label": "Viber", "type": "viber"},
    {"icon": "assets/icons/DotsH.svg", "label": "More", "type": "more"},
  ];

  static final List<Map<String, String>> _locationOptions = [
    {"icon": "assets/icons/map.svg", "label": "Maps"},
  ];

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLaunchFailure(String appName) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$appName is not installed or unavailable.")),
    );
  }

  Future<void> _handleShare(String type, String message) async {
    final encodedMessage = Uri.encodeComponent(message);

    switch (type) {
      case "messenger":
        final uri = Uri.parse("fb-messenger://share?link=$encodedMessage");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showLaunchFailure("Messenger");
        }
        break;
      case "whatsapp":
        final uri = Uri.parse("whatsapp://send?text=$encodedMessage");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showLaunchFailure("WhatsApp");
        }
        break;
      case "email":
        final uri =
        Uri.parse("mailto:?subject=Check this out&body=$encodedMessage");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showLaunchFailure("an email app");
        }
        break;
      case "sms":
        final uri = Uri.parse("sms:?body=$encodedMessage");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showLaunchFailure("an SMS app");
        }
        break;
      case "telegram":
        final uri = Uri.parse("tg://msg?text=$encodedMessage");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showLaunchFailure("Telegram");
        }
        break;
      case "viber":
        final uri = Uri.parse("viber://forward?text=$encodedMessage");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showLaunchFailure("Viber");
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final shareText =
            "Check out ${team['name']} location: ${team['link']}";

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Office name header inside sheet
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.apartment_rounded,
                          color: _primaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        team['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  "SHARE VIA",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _shareOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final opt = _shareOptions[index];
                      return _buildOption(opt["icon"]!, opt["label"]!, () {
                        Navigator.pop(context);
                        _handleShare(opt["type"]!, shareText);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  "LOCATION",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _locationOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final opt = _locationOptions[index];
                      return _buildOption(opt["icon"]!, opt["label"]!,
                              () async {
                            Navigator.pop(context);
                            final uri = Uri.parse(team['link']);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              _showLaunchFailure("Maps");
                            }
                          });
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
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(svgPath, width: 24, height: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
        backgroundColor: const Color(0xFFF5F6FA),
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            // 🔳 Gradient header
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 16, 20, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primaryColor, _primaryDark],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: isKeyboardOpen
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${teams.length} OFFICES",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Directories',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'MOO, Offices and Provinces locations',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          "assets/images/directories.png",
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
                secondChild: const Text(
                  'Directories',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // ✅ Floating search bar (overlaps header/body edge)
            Transform.translate(
              offset: const Offset(0, -22),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  shadowColor: Colors.black26,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search office...",
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: _primaryColor),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.grey, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => searchQuery = "");
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ),
            ),

            // ✅ Team list
            Expanded(
              child: filteredTeams.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 40, color: Colors.grey[350]),
                      const SizedBox(height: 12),
                      Text(
                        "No offices found",
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                itemCount: filteredTeams.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final team = filteredTeams[index];

                  return Material(
                    key: ValueKey(team['name']),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showBottomSheet(context, team),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.location_city_rounded,
                                  color: _primaryColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team['name'] ?? 'Unknown Team',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "${team['lat']}, ${team['long']}",
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.black45,
                                size: 18,
                              ),
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