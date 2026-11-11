import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shop/screens/notifications/notifications_details_screen.dart';
import 'package:shop/services/api_config.dart';

import '../../providers/auth_provider.dart';
import '../../route/route_constants.dart';

class NotificationItem {
  final String title;
  final String body;
  final DateTime receivedAt;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      title: json['title']?.toString() ?? 'N/A',
      body: json['body']?.toString() ??
          json['message']?.toString() ??
          'N/A',
      receivedAt: DateTime.tryParse(
        json['created_at']?.toString() ??
            json['sent_at']?.toString() ??
            '',
      ) ??
          DateTime.now(),
      isRead: json['status']?.toString() == 'read' ||
          json['is_read'] == true,
    );
  }
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  static final String _notificationsListUrl =
      '${ApiConfig.leaveBase}/notifications/list';

  void _addNotification(String title, String body) {
    if (!mounted) return;
    setState(() {
      _notifications.insert(
        0,
        NotificationItem(title: title, body: body, receivedAt: DateTime.now()),
      );
    });
  }

  /// Fetches the notifications list from the API for the current staff member.
  Future<void> _fetchNotifications({int page = 1, int perPage = 20}) async {
    final auth = ref.read(authProvider);
    final staffId = auth?.staffId;

    if (staffId == null) {
      debugPrint('No staff_id found on authProvider, skipping fetch.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    debugPrint('--- Fetching notifications ---');
    debugPrint('URL: $_notificationsListUrl');
    debugPrint('staffId: $staffId');

    try {
      final response = await http.post(
        Uri.parse(_notificationsListUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "staff_id": staffId,
          "status": "sent",
          "type": "fcm",
          "page": page,
          "per_page": perPage,
        }),
      );

      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint('Decoded: $decoded');

        // Handles both {"data": [...]} and a bare [...] response shape.
        final List<dynamic> items = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? decoded['notifications'] ?? [])
            : (decoded is List ? decoded : []);

        final fetched = items
            .whereType<Map<String, dynamic>>()
            .map((e) => NotificationItem.fromJson(e))
            .toList();

        if (!mounted) return;
        setState(() {
          _notifications
            ..clear()
            ..addAll(fetched);
        });
      } else {
        debugPrint(
          'Failed to fetch notifications: ${response.statusCode} ${response.body}',
        );
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to load notifications (${response.statusCode})';
        });
      }
    } catch (e, st) {
      debugPrint('Error fetching notifications: $e');
      debugPrint('Stack trace: $st');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong while loading notifications.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openDetails(NotificationItem item) {
    setState(() => item.isRead = true);
    print(item.body);
    Navigator.pushNamed(
      context,
      leaveActionScreenRoute,
      arguments: item.body.toString(),
    );
  }

  Future<void> firebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    String? token = await messaging.getToken();
    debugPrint("FCM TOKEN: $token");

    // Foreground notification: show a dialog AND add it to the list.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? "N/A";
      final body = message.notification?.body ?? "N/A";

      _addNotification(title, body);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(
            body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  leaveActionScreenRoute,
                  arguments: body,
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

    // Background notification tapped (app was in background, user tapped it).
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final title = message.notification?.title ?? "N/A";
      final body = message.notification?.body ?? "N/A";

      _addNotification(title, body);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              NotificationsDetailsScreen(body: body, title: title),
        ),
      );
    });

    // App opened directly from a terminated state via a notification tap.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final title = initialMessage.notification?.title ?? "N/A";
      final body = initialMessage.notification?.body ?? "N/A";

      _addNotification(title, body);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              NotificationsDetailsScreen(body: body, title: title),
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours} hours Ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return DateFormat('MMM d, yyyy').format(time);
  }

  /// Buckets a notification's date into "Today", "Yesterday", or a
  /// formatted date string, mirroring the grouped-list design.
  String _sectionLabelFor(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(time.year, time.month, time.day);
    final diff = today.difference(that).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    return DateFormat('MMM d, yyyy').format(time);
  }

  /// Groups notifications into ordered (label, items) sections, preserving
  /// the most-recent-first ordering already present in `_notifications`.
  List<MapEntry<String, List<NotificationItem>>> _groupedNotifications() {
    final Map<String, List<NotificationItem>> groups = {};
    for (final item in _notifications) {
      final label = _sectionLabelFor(item.receivedAt);
      groups.putIfAbsent(label, () => []).add(item);
    }
    return groups.entries.toList();
  }

  /// Picks an icon + tint that roughly matches the notification's content,
  /// e.g. purchases get a cart icon, event reminders get a calendar icon.
  ({IconData icon, Color color}) _iconFor(NotificationItem item) {
    final text = "${item.title} ${item.body}".toLowerCase();
    if (text.contains('purchas') || text.contains('order') || text.contains('cart')) {
      return (icon: Icons.shopping_cart_outlined, color: Colors.deepOrange);
    }
    if (text.contains('event') || text.contains('saved') || text.contains('ready')) {
      return (icon: Icons.calendar_today_outlined, color: Colors.deepOrange);
    }
    if (text.contains('concert') || text.contains('added') || text.contains('club')) {
      return (icon: Icons.celebration_outlined, color: Colors.pink);
    }
    return (icon: Icons.person_outline_rounded, color: Colors.blueGrey);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      firebaseMessaging();
      _fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          "Notification",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.black),
            onPressed: _notifications.isEmpty
                ? null
                : () => setState(() => _notifications.clear()),
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _notifications.isEmpty) {
      return _buildErrorState();
    }
    return _notifications.isEmpty ? _buildEmptyState() : _buildList();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(_errorMessage ?? 'Something went wrong'),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _fetchNotifications,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No notifications yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll let you know when\nsomething new comes in.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final sections = _groupedNotifications();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = sections[sectionIndex];
        final items = section.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: sectionIndex == 0 ? 8 : 20,
                bottom: 4,
              ),
              child: Text(
                section.key,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            for (int i = 0; i < items.length; i++)
              _buildNotificationTile(items[i], isLast: i == items.length - 1),
          ],
        );
      },
    );
  }

  Widget _buildNotificationTile(NotificationItem item, {required bool isLast}) {
    final iconData = _iconFor(item);

    return Dismissible(
      key: ValueKey(item.receivedAt.microsecondsSinceEpoch),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        setState(() => _notifications.remove(item));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: InkWell(
        onTap: () => _openDetails(item),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconData.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData.icon, color: iconData.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          TextSpan(
                            text: item.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (item.body.isNotEmpty)
                            TextSpan(text: " ${item.body}"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(item.receivedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}