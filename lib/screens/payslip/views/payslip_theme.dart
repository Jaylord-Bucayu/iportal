import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:intl/intl.dart';

// Shared design tokens and small widgets for the payslip screens.
// Save as: lib/screens/payslip/components/payslip_theme.dart
//
// Follows the app's light/dark setting (Theme.of(context).brightness), so the
// payslip screens never disagree with the rest of the app.

class PayslipPalette {
  const PayslipPalette._(this.dark);
  final bool dark;

  static PayslipPalette of(BuildContext context) =>
      PayslipPalette._(Theme.of(context).brightness == Brightness.dark);

  // Brand (the card looks the same in light and dark, like a physical card)
  static const brandBlue = Color(0xFF0038A8);
  static const brandBlueDeep = Color(0xFF001E5E);
  static const brandRed = Color(0xFFCE1126);
  static const brandRedDeep = Color(0xFF8E0B1B);

  // Card: deep teal-green with lime leaves (colors only, no logo or wordmark)
  static const cardTeal = Color(0xFF12806B);
  static const cardTealDeep = Color(0xFF0A5C52);
  static const cardLime = Color(0xFFB8E01C);
  static const leafYellow = Color(0xFFE4EC1C);
  static const leafGreen = Color(0xFF6DBE3F);
  static const leafDeep = Color(0xFF3F9E3A);

  // Surfaces
  // Page is light grey, cards sit on it in white (Apple "inset grouped").
  Color get bg => dark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
  Color get cell => dark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  Color get tile => dark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
  // Segmented control: grey track, white thumb.
  Color get track =>
      dark ? const Color(0x3D767680) : const Color(0x1F767680);
  Color get thumb => dark ? const Color(0xFF636366) : const Color(0xFFFFFFFF);
  Color get line => dark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6);

  // Content (contrast on its surface: ink 15:1, sub 5.2:1 light / 6.4:1 dark)
  Color get ink => dark ? const Color(0xFFF5F5F7) : const Color(0xFF1D1D1F);
  Color get sub => dark ? const Color(0xFF98989F) : const Color(0xFF636366);

  // Accents
  Color get tint => dark ? const Color(0xFF2F63E8) : brandBlue; // filled buttons
  Color get blue => dark ? const Color(0xFF5B8CFF) : brandBlue;
  Color get red => dark ? const Color(0xFFFF5A67) : brandRed;
  Color get slate => dark ? const Color(0xFF9AA7C4) : const Color(0xFF6B7A99);

  List<Color> get categories => [blue, red, slate];
  static const categoryNames = ['Contributions', 'Loans', 'Others'];
}

const _fontFallback = [
  '.SF Pro Text',
  'SF Pro Text',
  'Inter',
  'Segoe UI',
  'Roboto',
  'Helvetica Neue',
  'Arial',
];

/// Text style on the Apple type scale: 34 / 22 / 20 / 17 / 15 / 13 / 12 (never below 11).
TextStyle pText(double size, FontWeight weight, Color color,
    {double? ls, double? h}) =>
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      // Tracking depends on size: tighter as text grows, looser when small.
      letterSpacing: ls ?? _tracking(size),
      height: h,
      fontFamilyFallback: _fontFallback,
    );

double _tracking(double size) {
  if (size >= 28) return -size * 0.02;
  if (size >= 20) return -size * 0.012;
  if (size <= 13) return size * 0.012;
  return 0;
}

final NumberFormat _pesoFmt = NumberFormat('#,##0.00');
String payPeso(double v) => '₱${_pesoFmt.format(v)}';

double payNum(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0;
  return 0;
}

/// Zero duration when the person has turned animations off.
Duration payMotion(BuildContext context, int ms) =>
    MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : Duration(milliseconds: ms);

/// Spring from designer-friendly values: damping ratio (1 = no overshoot) and
/// response (seconds to reach the target). Mass is fixed at 1.
SpringDescription paySpring({double response = 0.35, double damping = 1.0}) {
  final k = math.pow(2 * math.pi / response, 2).toDouble();
  final c = 4 * math.pi * damping / response;
  return SpringDescription(mass: 1, stiffness: k, damping: c);
}

/// Scales down the instant a finger lands and springs back on release.
/// Interruptible: each change starts from the current on-screen scale and
/// keeps its velocity, so a quick tap never waits for the last animation.
class SpringPress extends StatefulWidget {
  const SpringPress({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<SpringPress> createState() => _SpringPressState();
}

class _SpringPressState extends State<SpringPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController.unbounded(vsync: this, value: 1);

  void _to(double target) {
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
      return;
    }
    _c.animateWith(SpringSimulation(
        paySpring(response: 0.3), _c.value, target, _c.velocity));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _to(widget.scale),
      onTapUp: widget.onTap == null ? null : (_) => _to(1),
      onTapCancel: widget.onTap == null ? null : () => _to(1),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) =>
            Transform.scale(scale: _c.value, child: child),
        child: widget.child,
      ),
    );
  }
}

/// Inset grouped container (like Settings): rounded, rows separated by hairlines
/// that start after the icon.
class PayslipGroup extends StatelessWidget {
  const PayslipGroup({super.key, required this.children, this.separatorIndent = 16});
  final List<Widget> children;
  final double separatorIndent;

  @override
  Widget build(BuildContext context) {
    final p = PayslipPalette.of(context);
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i != children.length - 1) {
        items.add(Container(
          height: 0.5,
          margin: EdgeInsets.only(left: separatorIndent),
          color: p.line,
        ));
      }
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.cell,
        borderRadius: BorderRadius.circular(18),
        // Increased-contrast setting: give the group a defined edge.
        border: MediaQuery.of(context).highContrast
            ? Border.all(color: p.sub, width: 1)
            : null,
      ),
      child: Column(children: items),
    );
  }
}

/// Tap target with an iOS-style highlight instead of a Material ripple.
class PayslipPressable extends StatelessWidget {
  const PayslipPressable({
    super.key,
    required this.onTap,
    required this.child,
    this.semanticLabel,
  });
  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = PayslipPalette.of(context);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: p.line.withOpacity(0.6),
          child: child,
        ),
      ),
    );
  }
}

/// iOS Calendar-style date icon: red label on top, large numeral below.
/// Light: white tile. Dark: charcoal tile (as the two Calendar icon variants).
class PayslipCalendarIcon extends StatelessWidget {
  const PayslipCalendarIcon({
    super.key,
    required this.label,
    required this.number,
    this.size = 44,
  });
  final String label;
  final String number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = PayslipPalette.of(context);
    final numeralColors = p.dark
        ? const [Color(0xFFFFFFFF), Color(0xFFB4B4B9)]
        : const [Color(0xFF1D1D1F), Color(0xFF6E6E73)];
    return ExcludeSemantics(
      child: MediaQuery(
        // Fixed-size icon: don't let text scaling break it.
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.23),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: p.dark
                  ? const [Color(0xFF2A2A2C), Color(0xFF111112)]
                  : const [Color(0xFFFFFFFF), Color(0xFFE9E9EC)],
            ),
            border: Border.all(
              color: p.dark
                  ? const Color(0x1FFFFFFF)
                  : const Color(0x14000000),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(p.dark ? 0.35 : 0.10),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: pText(11, FontWeight.w700, const Color(0xFFFF3B30),
                      ls: 0, h: 1.0)),
              const SizedBox(height: 1),
              ShaderMask(
                shaderCallback: (r) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: numeralColors,
                ).createShader(r),
                blendMode: BlendMode.srcIn,
                child: Text(number,
                    style: pText(22, FontWeight.w300, Colors.white,
                        ls: -0.5, h: 1.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Silver contact chip.
class PayslipChip extends StatelessWidget {
  const PayslipChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F4F6), Color(0xFFB9BDC8)],
        ),
      ),
      child: CustomPaint(painter: _ChipLinesPainter()),
    );
  }
}

class _ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final w = size.width, h = size.height;
    canvas.drawLine(Offset(0, h * 0.34), Offset(w, h * 0.34), p);
    canvas.drawLine(Offset(0, h * 0.66), Offset(w, h * 0.66), p);
    canvas.drawLine(Offset(w * 0.36, 0), Offset(w * 0.36, h), p);
    canvas.drawLine(Offset(w * 0.64, 0), Offset(w * 0.64, h), p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.36, h * 0.34, w * 0.28, h * 0.32),
        const Radius.circular(3),
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Card background: teal-green gradient, fine pinstripes, one sweeping lime
/// outline and layered leaf shapes rising from the bottom-right corner.
class PayslipCardArt extends StatelessWidget {
  const PayslipCardArt({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [PayslipPalette.cardTeal, PayslipPalette.cardTealDeep],
            ),
          ),
        ),
        CustomPaint(painter: _CardArtPainter()),
      ],
    );
  }
}

class _CardArtPainter extends CustomPainter {
  const _CardArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    final stripe = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..strokeWidth = 1;
    for (double x = -h; x < w; x += 7) {
      canvas.drawLine(Offset(x, h), Offset(x + h, 0), stripe);
    }

    // Sweeping lime outline
    final outline = Path()
      ..moveTo(-10, h * 0.95)
      ..cubicTo(w * 0.02, h * 0.1, w * 0.52, -h * 0.08, w * 0.68, h * 0.06)
      ..cubicTo(w * 0.78, h * 0.4, w * 0.62, h * 0.8, w * 0.4, h * 1.05);
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = PayslipPalette.cardLime.withOpacity(0.85),
    );

    // Leaf 1: yellow-lime to green
    final leaf1 = Path()
      ..moveTo(w * 0.46, h + 10)
      ..cubicTo(w * 0.58, h * 0.78, w * 0.84, h * 0.64, w + 10, h * 0.58)
      ..lineTo(w + 10, h + 10)
      ..close();
    canvas.drawPath(
      leaf1,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [PayslipPalette.leafYellow, PayslipPalette.leafGreen],
        ).createShader(rect),
    );

    // Leaf 2: deeper green overlay
    final leaf2 = Path()
      ..moveTo(w * 0.66, h + 10)
      ..cubicTo(w * 0.74, h * 0.86, w * 0.9, h * 0.78, w + 10, h * 0.74)
      ..lineTo(w + 10, h + 10)
      ..close();
    canvas.drawPath(
      leaf2,
      Paint()..color = PayslipPalette.leafDeep.withOpacity(0.7),
    );

    // Highlight along leaf 1's edge
    final edge = Path()
      ..moveTo(w * 0.46, h + 10)
      ..cubicTo(w * 0.58, h * 0.78, w * 0.84, h * 0.64, w + 10, h * 0.58);
    canvas.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}