import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/screens/payslip/views/payslip_breakdown_screen.dart';
import 'package:shop/screens/payslip/views/payslip_theme.dart';

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipPageState();
}

class _PayslipPageState extends State<PayslipScreen> {
  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Earliest year payslips are shown for.
  static const int _firstYear = 2026;

  final DateTime _now = DateTime.now();
  int _tab = 0; // 0 Current, 1 Last 6 months, 2 By year
  late int _selectedYear = math.max(_now.year, _firstYear);
  late final List<int> _years = List<int>.generate(
    math.max(1, _now.year - _firstYear + 1),
        (i) => _firstYear + i,
  );

  // DateTime normalises month <= 0, so Jan - 1 becomes Dec of last year.
  // Anything before _firstYear is dropped.
  List<DateTime> get _lastSixMonths => List.generate(
    6,
        (i) => DateTime(_now.year, _now.month - i, 1),
  ).where((d) => d.year >= _firstYear).toList();

  bool _isFuture(int year, int month) =>
      DateTime(year, month).isAfter(DateTime(_now.year, _now.month));

  bool _isCurrent(int year, int month) =>
      year == _now.year && month == _now.month;

  String _range(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    final f = DateFormat('d MMM yyyy');
    return '${f.format(start)} - ${f.format(end)}';
  }

  void _open(int year, int month, {bool viaRoute = false}) {
    final name = _months[month - 1];
    if (viaRoute) {
      Navigator.pushNamed(
        context,
        payslipBreakdownScreenRoute,
        arguments: {'month': name, 'year': year},
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PayslipBreakdownScreen(month: name, year: year),
        ),
      );
    }
  }

  void _setTab(int v) {
    if (v == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = v);
  }

  Widget _tabContent(PayslipPalette p) {
    switch (_tab) {
      case 1:
        return _lastSixTab();
      case 2:
        return _yearTab(p);
      default:
        return _currentTab(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = PayslipPalette.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: p.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: CupertinoTheme(
            data: CupertinoTheme.of(context).copyWith(primaryColor: p.tint),
            child: LayoutBuilder(
              builder: (context, c) {
                final pad = c.maxWidth >= 600 ? 32.0 : 20.0;
                return Stack(
                  children: [
                    CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      slivers: [
                        // Same app bar as the payslip breakdown screen.
                        SliverAppBar(
                          pinned: true,
                          automaticallyImplyLeading: false,
                          backgroundColor: p.bg.withOpacity(0.9),
                          surfaceTintColor: Colors.transparent,
                          elevation: 0,
                          scrolledUnderElevation: 0,
                          toolbarHeight: 72,
                          centerTitle: true,
                          leadingWidth: 76,
                          leading: Navigator.of(context).canPop()
                              ? const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 20),
                              child: _RoundBackButton(),
                            ),
                          )
                              : null,
                          title: Text('Payslips',
                              style: pText(17, FontWeight.w600, p.ink)),
                        ),
                        // Extra bottom space so the last row can scroll
                        // clear of the floating bar.
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                pad, 8, pad, 120 + bottomInset),
                            child: _tabContent(p),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: math.max(bottomInset, 12) + 8,
                      child: Center(
                        child: _GlassTabBar(tab: _tab, onChanged: _setTab),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Current month ──────────────────────────────────────────────────────────
  Widget _currentTab(PayslipPalette p) {
    final m = _now.month;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text('This month', style: pText(13, FontWeight.w400, p.sub)),
        ),
        PayslipGroup(
          separatorIndent: 76,
          children: [
            _MonthRow(
              short: DateFormat('MMM').format(DateTime(_now.year, m)),
              number: m,
              title: '${_months[m - 1]} ${_now.year}',
              subtitle: _range(_now.year, m),
              isCurrent: true,
              onTap: () => _open(_now.year, m),
            ),
          ],
        ),
      ],
    );
  }

  // ── Last six months ────────────────────────────────────────────────────────
  Widget _lastSixTab() {
    return PayslipGroup(
      separatorIndent: 76,
      children: [
        for (final d in _lastSixMonths)
          _MonthRow(
            short: DateFormat('MMM').format(d),
            number: d.month,
            title: '${_months[d.month - 1]} ${d.year}',
            subtitle: _range(d.year, d.month),
            isCurrent: _isCurrent(d.year, d.month),
            onTap: () => _open(d.year, d.month),
          ),
      ],
    );
  }

  // ── By year ────────────────────────────────────────────────────────────────
  Widget _yearTab(PayslipPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _years.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final y = _years[i];
              final selected = y == _selectedYear;
              return Semantics(
                button: true,
                selected: selected,
                label: '$y',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedYear = y);
                  },
                  child: AnimatedContainer(
                    duration: payMotion(context, 180),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? p.tint : p.cell,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text('$y',
                        style: pText(15, FontWeight.w600,
                            selected ? Colors.white : p.ink)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        PayslipGroup(
          separatorIndent: 76,
          children: [
            for (var m = 1; m <= 12; m++)
              _MonthRow(
                short: DateFormat('MMM').format(DateTime(_selectedYear, m)),
                number: m,
                title: _months[m - 1],
                subtitle: _isFuture(_selectedYear, m)
                    ? 'Not available yet'
                    : _range(_selectedYear, m),
                isCurrent: _isCurrent(_selectedYear, m),
                disabled: _isFuture(_selectedYear, m),
                onTap: () => _open(_selectedYear, m, viaRoute: true),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Round back button (identical to the breakdown screen's)
// ─────────────────────────────────────────────────────────────────────────────
class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton();

  @override
  Widget build(BuildContext context) {
    final p = PayslipPalette.of(context);
    return Semantics(
      button: true,
      label: 'Back',
      excludeSemantics: true,
      child: SpringPress(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: p.cell,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(p.dark ? 0.4 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(CupertinoIcons.chevron_left, size: 22, color: p.ink),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating glass tab bar
// One frosted pill, three items: 6 months (left), Current (centre), Year
// (right). A soft glass thumb slides under the selected item.
// ─────────────────────────────────────────────────────────────────────────────
class _GlassTabBar extends StatelessWidget {
  final int tab; // 0 Current, 1 Last 6 months, 2 By year
  final ValueChanged<int> onChanged;

  const _GlassTabBar({required this.tab, required this.onChanged});

  // Visual order, left to right, as tab ids.
  static const List<int> _order = [1, 0, 2];

  static const Map<int, String> _labels = {
    0: 'Current',
    1: '6 months',
    2: 'Year',
  };

  static const Map<int, IconData> _icons = {
    0: CupertinoIcons.doc_text,
    1: CupertinoIcons.clock,
    2: CupertinoIcons.calendar,
  };

  @override
  Widget build(BuildContext context) {
    final p = PayslipPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final idx = _order.indexOf(tab);

    final glassFill = dark
        ? Colors.white.withOpacity(0.10)
        : Colors.white.withOpacity(0.58);
    final rim = dark
        ? Colors.white.withOpacity(0.22)
        : Colors.white.withOpacity(0.85);
    final thumb = dark
        ? Colors.white.withOpacity(0.16)
        : Colors.black.withOpacity(0.07);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            height: 62,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(31),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.45 : 0.14),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(31),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: glassFill,
                      borderRadius: BorderRadius.circular(31),
                      border: Border.all(color: rim, width: 1),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(dark ? 0.10 : 0.35),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Stack(
                        children: [
                          AnimatedAlign(
                            duration: payMotion(context, 320),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment((idx - 1).toDouble(), 0),
                            child: FractionallySizedBox(
                              widthFactor: 1 / 3,
                              heightFactor: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: thumb,
                                  borderRadius: BorderRadius.circular(27),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              for (final t in _order)
                                Expanded(
                                  child: _GlassTabItem(
                                    label: _labels[t]!,
                                    icon: _icons[t]!,
                                    selected: t == tab,
                                    selectedColor: p.ink,
                                    idleColor: p.sub,
                                    onTap: () => onChanged(t),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final Color idleColor;
  final VoidCallback onTap;

  const _GlassTabItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.idleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : idleColor;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(label,
                maxLines: 1, style: pText(10.5, FontWeight.w600, color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────
class _MonthRow extends StatelessWidget {
  final String short;
  final int number;
  final String title;
  final String subtitle;
  final bool isCurrent;
  final bool disabled;
  final VoidCallback onTap;

  const _MonthRow({
    required this.short,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isCurrent = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = PayslipPalette.of(context);
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: PayslipPressable(
        onTap: disabled ? null : onTap,
        semanticLabel: '$title${isCurrent ? ', current month' : ''}. $subtitle',
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                PayslipCalendarIcon(label: short, number: '$number'),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: pText(17, FontWeight.w500, p.ink)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: pText(13, FontWeight.w400, p.sub)),
                    ],
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.tint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Current',
                        style: pText(12, FontWeight.w600, Colors.white)),
                  ),
                ],
                if (!disabled) ...[
                  const SizedBox(width: 8),
                  Icon(CupertinoIcons.chevron_right, size: 15, color: p.sub),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}