import 'package:flutter/material.dart';

// ─── Design tokens (mirrors your eGov palette) ───────────────────────────────

abstract class _C {
  static const primary     = Color(0xFF1B3FA0);
  static const bg          = Color(0xFFF2F4F8);
  static const surface     = Color(0xFFFFFFFF);
  static const divider     = Color(0xFFE2E8F0);
  static const textHi      = Color(0xFF0F1F3D);
  static const textMid     = Color(0xFF4A5568);
  static const textLow     = Color(0xFF9BAAB8);

  static const approvedFg  = Color(0xFF0A7E4A);
  static const approvedBg  = Color(0xFFE6F7EF);
  static const approvedBar = Color(0xFF0FB86A);
  static const pendingFg   = Color(0xFFB45309);
  static const pendingBg   = Color(0xFFFEF3DC);
  static const pendingBar  = Color(0xFFF59E0B);
  static const rejectedFg  = Color(0xFFB91C1C);
  static const rejectedBg  = Color(0xFFFFEBEB);
  static const rejectedBar = Color(0xFFEF4444);
  static const neutralFg   = Color(0xFF4A5568);
  static const neutralBg   = Color(0xFFF1F5F9);
  static const neutralBar  = Color(0xFF94A3B8);
}

// ─── Status helpers ───────────────────────────────────────────────────────────

class _StatusStyle {
  final Color fg, bg, bar;
  const _StatusStyle({required this.fg, required this.bg, required this.bar});

  static _StatusStyle of(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const _StatusStyle(fg: _C.approvedFg, bg: _C.approvedBg, bar: _C.approvedBar);
      case 'pending':
        return const _StatusStyle(fg: _C.pendingFg,  bg: _C.pendingBg,  bar: _C.pendingBar);
      case 'rejected':
      case 'declined':
        return const _StatusStyle(fg: _C.rejectedFg, bg: _C.rejectedBg, bar: _C.rejectedBar);
      default:
        return const _StatusStyle(fg: _C.neutralFg,  bg: _C.neutralBg,  bar: _C.neutralBar);
    }
  }
}

// ─── LeaveHistoryItem ─────────────────────────────────────────────────────────

class LeaveHistoryItem extends StatelessWidget {
  final String title;
  final String date;
  final String status;

  const LeaveHistoryItem({
    super.key,
    required this.title,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final st = _StatusStyle.of(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
       
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title & date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _C.textHi,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: _C.textLow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _C.textMid,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: st.bg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: st.fg,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Usage example ────────────────────────────────────────────────────────────
//
// Padding(
//   padding: const EdgeInsets.all(16),
//   child: Column(
//     children: [
//       LeaveHistoryItem(
//         title: "Vacation Leave",
//         date: "Feb 1, 2026 - Feb 5, 2026",
//         status: "Approved",
//       ),
//       SizedBox(height: 10),
//       LeaveHistoryItem(
//         title: "Sick Leave",
//         date: "Jan 15, 2026",
//         status: "Pending",
//       ),
//     ],
//   ),
// )