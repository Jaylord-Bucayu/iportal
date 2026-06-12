import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shop/components/ask_ai_button.dart';
import 'package:shop/components/leave/leave_icon.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/leave_type_model.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/screens/home/views/components/upcoming_leaves.dart';
import 'package:shop/screens/leaves/components/LeaveHistoryFewItems.dart';
import 'package:shop/screens/leaves/components/LeaveHistoryList.dart';
import 'package:shop/screens/leaves/components/PendingLeaveRequest.dart';
import 'package:shop/services/leaves/leave_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventItem {
  final String id;
  final String leave_type;
  final String staff_name;
  final String imageUrl;

  EventItem({
    required this.id,
    required this.leave_type,
    required this.staff_name,
    required this.imageUrl,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id'].toString(),
      leave_type: json['leave_type']['name'] ?? '',
      staff_name: json['staff_name'] ?? '',
      imageUrl: json['employee_image'] ?? '',
    );
  }
}

class LeavesScreen extends ConsumerStatefulWidget {
  const LeavesScreen({super.key});

  @override
  ConsumerState<LeavesScreen> createState() => _LeavesScreenState();
}


class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      )..repeat(reverse: true, period: Duration(milliseconds: 900 + i * 150));
    });

    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: -5).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    // stagger the dots
    Future.delayed(const Duration(milliseconds: 150),
        () => mounted ? _controllers[1].forward() : null);
    Future.delayed(const Duration(milliseconds: 300),
        () => mounted ? _controllers[2].forward() : null);
    _controllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)        // tip pointing left toward avatar
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) => false;
}

class _LeavesScreenState extends ConsumerState<LeavesScreen> {
  LeaveBalance? leaveBalance;
  bool loading = true;
  List<Map<String, dynamic>> pendingLeaves = [];

  // AI Coach state
  String? _aiCoachMessage;
  bool _aiLoading = true;
  List<dynamic> _leaveHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authUser = ref.read(authProvider);
      final staffId = authUser?.staffId ?? 0;
      fetchLeaveBalance(staffId);
      _loadLeaves(staffId);
      // _fetchLeaveHistoryAndAnalyze(staffId);
    });
  }

  Future<void> fetchLeaveBalance(int staffId) async {
    try {
      final result = await LeavesApi.getLeaveBalance(staffId);
      if (!mounted) return;
      setState(() {
        leaveBalance = result;
        loading = false;
      });
    } catch (e) {
      print("Error fetching leave balance: $e");
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _loadLeaves(int staffId) async {
    try {
      final data = await LeavesApi.fetchPendingLeaves(staffId: staffId);
      setState(() {
        pendingLeaves = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        pendingLeaves = [];
        loading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authProvider);
    final staffId = int.tryParse(authUser?.staffId.toString() ?? '0') ?? 0;
    final primaryColor = Colors.primaries[4];
    final roles = authUser?.roles ?? [];
    final double aiButtonBottom = pendingLeaves.isEmpty ? 20 : 90;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Text(
          'Leave Applications',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: C.textHi,
            letterSpacing: -0.4,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20.0),
          onPressed: () => Navigator.of(context).pop(),
        ),
      actions: [
  Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, applyLeaveScreenRoute,
            arguments: staffId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F0FF),         
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, size: 14, color: Color(0xFF0866FF)),
            SizedBox(width: 4),
            Text(
              'Apply',
              style: TextStyle(color: Color(0xFF0866FF), fontSize: 12,fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  ),
  Padding(
    padding: const EdgeInsets.only(right: 12),
    child: GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, viewLeaveLedgerScreenRoute,
            arguments: staffId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 14, color: Colors.white),
          ],
        ),
      ),
    ),
  ),
],),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await fetchLeaveBalance(staffId);
              await _loadLeaves(staffId);
              setState(() {
                _aiLoading = true;
                _aiCoachMessage = null;
              });
              // await _fetchLeaveHistoryAndAnalyze(staffId);
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── AI COACH CARD ──────────────────────────────────────
                  // Padding(
                  //   padding: const EdgeInsets.all(16),
                  //   child: leaveCoachCard(
                  //   ),
                  // ),
                   SizedBox(height: 12),
                  // Upcoming Leaves (SUPERVISOR)
                  if (roles.contains('supervisor'))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: UpcomingLeaves(
                          status: 'supervisor', authorityId: staffId),
                    ),
                  
                  SizedBox(height: 12),
                  // Upcoming Leaves (APPROVER)
                  if (roles.contains('approver'))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: UpcomingLeaves(
                          status: 'approver', authorityId: staffId),
                    ),

                  const SizedBox(height: 8),

                  // Leave Balance Header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Leave Balances',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Leave Balance Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : leaveBalance == null
                            ? const Center(
                                child: Text(
                                  "Failed to fetch leave balance",
                                  style: TextStyle(color: Colors.red),
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  SizedBox(
                                    width: (MediaQuery.of(context).size.width -
                                            16 * 2 -
                                            8) /
                                        2,
                                    child: leaveCard(
                                      'Sick',
                                      leaveBalance?.sickLeave.toString() ??
                                          '0.0',
                                      'assets/images/face-with-thermometer.png',
                                      Colors.black,
                                    ),
                                  ),
                                  SizedBox(
                                    width: (MediaQuery.of(context).size.width -
                                            16 * 2 -
                                            8) /
                                        2,
                                    child: leaveCard(
                                      'Vacation',
                                      leaveBalance?.vacationLeave.toString() ??
                                          '0.0',
                                      'assets/images/tent.png',
                                      Colors.black,
                                    ),
                                  ),
                                  SizedBox(
                                    width: (MediaQuery.of(context).size.width -
                                            16 * 2 -
                                            8) /
                                        2,
                                    child: leaveCard(
                                      'SPL',
                                      leaveBalance?.specialPrivilegeLeave
                                              .toString() ??
                                          '0.0',
                                      'assets/images/spl.png',
                                      Colors.black,
                                    ),
                                  ),
                                  SizedBox(
                                    width: (MediaQuery.of(context).size.width -
                                            16 * 2 -
                                            8) /
                                        2,
                                    child: leaveCard(
                                      'Force',
                                      leaveBalance?.forceLeave.toString() ??
                                          '0.0',
                                      'assets/images/force.png',
                                      Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                  ),

                  const SizedBox(height: 8),

                  // Recent Transactions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Transactions',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, 'view_all_leaves', arguments: staffId);
                              },
                              child: Text(
                                'See All',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: LeaveHistoryComponent(staffId: staffId),
                      ),
                    ],
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
            
          ),

          // Floating AI button
          // Positioned(
          //   right: 10,
          //   bottom: aiButtonBottom,
          //   child: FloatingAIButton(
          //     onTap: () => Navigator.pushNamed(context, leaveChatScreenRoute),
          //     label: 'Angelo AI',
          //   ),
          // ),

          // Pending Leave Request
          if (!loading && pendingLeaves.isNotEmpty)
            PendingLeaveRequest(
              imagePath: leaveConfig[pendingLeaves[0]['leave_type']
                  ['name']]?['image'],
              leaveData: pendingLeaves[0],
            ),
        ],
      ),
      
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AI LEAVE COACH CARD
  // ─────────────────────────────────────────────────────────────────────────
// Widget leaveCoachCard() {
//   final imagePath = switch (_aiEmotion) {
//     'proud'   => 'assets/bot/proud.png',
//     'happy'   => 'assets/bot/joy.png',
//     'worried' => 'assets/bot/worried.png',
//     'sad'     => 'assets/bot/sad.png',
//     _         => 'assets/bot/neutral.png',
//   };

//   return Row(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       // ── Avatar on the LEFT ──
//       ClipRRect(
//         borderRadius: BorderRadius.circular(8),
//         child: Image.asset(
//           imagePath,
//           width: 40,
//           height: 40,
//           fit: BoxFit.cover,
//         ),
//       ),
//       const SizedBox(width: 8),

//       // ── Chat bubble on the RIGHT ──
//       Expanded(
//         child: Stack(
//           clipBehavior: Clip.none,
//           children: [
//             Positioned(
//               left: -9,
//               top: 15,
//               child: CustomPaint(
//                 size: const Size(10, 12),
//                 painter: _BubbleTailPainter(),
//               ),
//             ),
//             Container(
//               margin: const EdgeInsets.only(top: 4),
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(4),
//                   topRight: Radius.circular(16),
//                   bottomRight: Radius.circular(16),
//                   bottomLeft: Radius.circular(16),
//                 ),
//               ),
//               child: _aiLoading
//                   ? _TypingIndicator()
//                   : Text(
//                       _aiCoachMessage ?? 'No insights yet.',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[700],
//                         height: 1.4,
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     ],
//   );
// }
  
  // ─────────────────────────────────────────────────────────────────────────
  // Existing widgets below — unchanged
  // ─────────────────────────────────────────────────────────────────────────

  Widget upcomingSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  Widget leaveHistoryCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  Widget leaveCard(
      String title, String balance, String imagePath, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    balance,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: -10,
              right: -20,
              child: Image.asset(
                imagePath,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}