import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Tokens ───────────────────────────────────────────────────────────────────
class _T {
  static const blue       = Color(0xFF0866FF);
  static const blueSoft   = Color(0xFFE7F0FF);
  static const purple     = Color(0xFF9340CC);
  static const purpleSoft = Color(0xFFF5EBFF);
  static const green      = Color(0xFF10B981);
  static const greenSoft  = Color(0xFFD1FAE5);
  static const amber      = Color(0xFFF59E0B);
  static const amberSoft  = Color(0xFFFEF3C7);

  static const bg          = Color(0xFFF0F2F5);
  static const surface     = Color(0xFFFFFFFF);
  static const divider     = Color(0xFFE4E6EB);
  static const textPrimary = Color(0xFF050505);
  static const textSub     = Color(0xFF65676B);
  static const textMuted   = Color(0xFF8A8D91);
}

// ─── Portion resolver ────────────────────────────────────────────────────────
({Color bg, Color fg, String label}) _portion(String type) {
  final t = type.toLowerCase();
  if (t == 'am' || t.contains('morning'))
    return (bg: _T.blueSoft,   fg: _T.blue,   label: 'AM');
  if (t == 'pm' || t.contains('afternoon'))
    return (bg: _T.purpleSoft, fg: _T.purple, label: 'PM');
  if (t.contains('half'))
    return (bg: _T.amberSoft,  fg: _T.amber,  label: 'HALF');
  return   (bg: _T.blueSoft,  fg: _T.blue,  label: 'WHOLE');
}

// ─── Model ───────────────────────────────────────────────────────────────────
class LeaveDate {
  final DateTime date;
  final String type;

  const LeaveDate({required this.date, required this.type});

  factory LeaveDate.fromJson(Map<String, dynamic> json) => LeaveDate(
        date: DateTime.parse(json['date'] as String),
        type: json['type'] as String? ?? 'Full Day',
      );

  String get formattedDate => DateFormat('MMMM d, yyyy').format(date);
  String get dayName       => DateFormat('EEEE').format(date);
  String get monthShort    => DateFormat('MMM').format(date).toUpperCase();
  String get dayNum        => date.day.toString();
}

enum LeaveDatesViewType { list, calendar, timeline }

// ─── Root widget ─────────────────────────────────────────────────────────────
class EnhancedLeaveDatesSection extends StatefulWidget {
  final List<dynamic> rawDates;
  final LeaveDatesViewType defaultView;

  const EnhancedLeaveDatesSection({
    super.key,
    required this.rawDates,
    this.defaultView = LeaveDatesViewType.timeline,
  });

  @override
  State<EnhancedLeaveDatesSection> createState() =>
      _EnhancedLeaveDatesSectionState();
}

class _EnhancedLeaveDatesSectionState
    extends State<EnhancedLeaveDatesSection> {
  late List<LeaveDate> _dates;

  @override
  void initState() {
    super.initState();
    _dates = widget.rawDates
        .map((d) => d is Map<String, dynamic> ? LeaveDate.fromJson(d) : null)
        .whereType<LeaveDate>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_dates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const Text(
                'Leave Dates',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _T.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _T.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_dates.length} day${_dates.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Timeline ──────────────────────────────────────────
        _Timeline(dates: _dates),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── Timeline ────────────────────────────────────────────────────────────────
class _Timeline extends StatelessWidget {
  final List<LeaveDate> dates;
  const _Timeline({required this.dates});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: dates.asMap().entries.map((e) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 250 + (e.key * 60)),
          curve: Curves.easeOutCubic,
          builder: (_, val, child) => Opacity(
            opacity: val,
            child: Transform.translate(
                offset: Offset(0, (1 - val) * 6), child: child),
          ),
          child: _TimelineRow(
            date: e.value,
            index: e.key,
            isLast: e.key == dates.length - 1,
          ),
        );
      }).toList(),
    );
  }
}

// ─── Single timeline row ─────────────────────────────────────────────────────
class _TimelineRow extends StatelessWidget {
  final LeaveDate date;
  final int index;
  final bool isLast;

  const _TimelineRow({
    required this.date,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final p = _portion(date.type);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Left: dot + line ────────────────────────────────
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 14),
                  decoration: BoxDecoration(
                    color: p.fg,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.bg, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: p.fg.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1)),
                    ],
                  ),
                ),
                // Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            p.fg.withOpacity(0.30),
                            _T.divider.withOpacity(0.60),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Right: card ──────────────────────────────────────
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
              padding: const EdgeInsets.fromLTRB(2, 10, 12, 10),
              child: Row(
                children: [
                  // Day block
                  Container(
                    width: 42,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: p.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          date.monthShort,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: p.fg,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          date.dayNum,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: p.fg,
                            height: 1.0,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Day info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date.dayName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _T.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          date.formattedDate,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _T.textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Portion pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: p.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: p.fg,
                        letterSpacing: 0.4,
                      ),
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
}