import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ComingSoonScreen(),
    );
  }
}

class ComingSoonScreen extends StatefulWidget {
  const ComingSoonScreen({super.key});

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late AnimationController _shimmerController;

  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;

  final List<_FloatingEmoji> _floatingEmojis = [];

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation =
        Tween<double>(begin: 0, end: 2 * pi).animate(_rotateController);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _generateFloatingEmojis();
  }

  void _generateFloatingEmojis() {
    final emojis = ['🌿', '🌺', '🦜', '🐍', '⚡', '🌙', '☀️', '🌊', '🪶', '🌴', '💎', '🔮'];
    final rand = Random();
    for (int i = 0; i < 14; i++) {
      _floatingEmojis.add(_FloatingEmoji(
        emoji: emojis[rand.nextInt(emojis.length)],
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        size: 16 + rand.nextDouble() * 22,
        speed: 1.5 + rand.nextDouble() * 2,
        phase: rand.nextDouble() * 2 * pi,
        amplitude: 6 + rand.nextDouble() * 12,
      ));
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // ── Background gradient mesh ──
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  Color(0xFF1A2A1A),
                  Color(0xFF0D1117),
                  Color(0xFF0A0D12),
                ],
              ),
            ),
          ),

          // ── Rotating outer ring ──
          Center(
            child: AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: List.generate(8, (i) {
                        final angle = (i / 8) * 2 * pi;
                        return Positioned(
                          left: 160 + 155 * cos(angle) - 10,
                          top: 160 + 155 * sin(angle) - 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFD4AF37).withOpacity(0.4),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Floating background emojis ──
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Stack(
                children: _floatingEmojis.map((e) {
                  final yOffset = sin(_floatController.value * 2 * pi + e.phase) * e.amplitude;
                  return Positioned(
                    left: e.x * size.width,
                    top: e.y * size.height + yOffset,
                    child: Opacity(
                      opacity: 0.15,
                      child: Text(e.emoji, style: TextStyle(fontSize: e.size)),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // ── Main content ──
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Sun glyph ──
                  AnimatedBuilder(
                    animation: Listenable.merge([_floatAnimation, _pulseAnimation]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value * 0.6),
                        child: Transform.scale(
                          scale: _pulseAnimation.value,
                          child: _MayaSunGlyph(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 36),

                  // ── Coming Soon text with shimmer ──
                  AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment(_shimmerAnimation.value - 1, 0),
                            end: Alignment(_shimmerAnimation.value, 0),
                            colors: const [
                              Color(0xFFD4AF37),
                              Color(0xFFFFEA80),
                              Color(0xFFD4AF37),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'COMING SOON',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 10,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // ── Main headline ──
                  const Text(
                    'Ik\'il',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF5ECD7),
                      height: 0.95,
                      letterSpacing: -2,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ── Sub headline ──
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF4CAF7D), Color(0xFF81D4A0)],
                    ).createShader(bounds),
                    child: const Text(
                      '✨ Something sacred is awakening ✨',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Emoji row ──
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildEmojiChip('🌿', 'Nature', 0),
                          const SizedBox(width: 10),
                          _buildEmojiChip('🦜', 'Spirit', 1),
                          const SizedBox(width: 10),
                          _buildEmojiChip('☀️', 'Sol', 2),
                          const SizedBox(width: 10),
                          _buildEmojiChip('🌺', 'Bloom', 3),
                          const SizedBox(width: 10),
                          _buildEmojiChip('💎', 'Jade', 4),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 44),

                  // ── Divider glyphs ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _glyphDot(),
                      const SizedBox(width: 8),
                      _glyphLine(),
                      const SizedBox(width: 8),
                      _glyphDiamond(),
                      const SizedBox(width: 8),
                      _glyphLine(),
                      const SizedBox(width: 8),
                      _glyphDot(),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // ── Notify button ──
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.98 + (_pulseAnimation.value - 0.95) * 0.4,
                        child: _NotifyButton(),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── Bottom tagline ──
                  Text(
                    '🌊  The ancient calendar counts down  🌊',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFFF5ECD7).withOpacity(0.35),
                      letterSpacing: 1,
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

  Widget _buildEmojiChip(String emoji, String label, int index) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final offset = sin(_floatController.value * 2 * pi + index * 0.8) * 5;
        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2D1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4CAF7D).withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: const Color(0xFF4CAF7D).withOpacity(0.8),
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _glyphDot() => Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFD4AF37).withOpacity(0.5),
        ),
      );

  Widget _glyphLine() => Container(
        width: 30,
        height: 1,
        color: const Color(0xFFD4AF37).withOpacity(0.3),
      );

  Widget _glyphDiamond() => Transform.rotate(
        angle: pi / 4,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.6),
              width: 1.5,
            ),
          ),
        ),
      );
}

// ── Maya Sun Glyph Widget ──────────────────────────────────────────────────
class _MayaSunGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 130,
      child: CustomPaint(
        painter: _SunGlyphPainter(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('☀️', style: TextStyle(fontSize: 32)),
              SizedBox(height: 2),
              Text(
                '𝕸',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFD4AF37),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SunGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Outer ring
    paint.color = const Color(0xFFD4AF37).withOpacity(0.5);
    canvas.drawCircle(center, 60, paint);

    // Inner ring
    paint.color = const Color(0xFF4CAF7D).withOpacity(0.4);
    canvas.drawCircle(center, 44, paint);

    // Sun rays
    paint.color = const Color(0xFFD4AF37).withOpacity(0.6);
    paint.strokeWidth = 2;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      final inner = Offset(center.dx + 46 * cos(angle), center.dy + 46 * sin(angle));
      final outer = Offset(center.dx + 58 * cos(angle), center.dy + 58 * sin(angle));
      canvas.drawLine(inner, outer, paint);
    }

    // Small tick marks on outer ring
    paint.color = const Color(0xFFD4AF37).withOpacity(0.3);
    paint.strokeWidth = 1;
    for (int i = 0; i < 20; i++) {
      final angle = (i / 20) * 2 * pi;
      final inner = Offset(center.dx + 61 * cos(angle), center.dy + 61 * sin(angle));
      final outer = Offset(center.dx + 65 * cos(angle), center.dy + 65 * sin(angle));
      canvas.drawLine(inner, outer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Notify Button ─────────────────────────────────────────────────────────
class _NotifyButton extends StatefulWidget {
  @override
  State<_NotifyButton> createState() => _NotifyButtonState();
}

class _NotifyButtonState extends State<_NotifyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E5E3E), Color(0xFF3D7A52)],
            ),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: const Color(0xFF4CAF7D).withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF7D).withOpacity(0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          // child: Row(
          //   mainAxisSize: MainAxisSize.min,
          //   children: const [
          //     Text('🔔', style: TextStyle(fontSize: 16)),
          //     SizedBox(width: 10),
          //     Text(
          //       'Notify Me',
          //       style: TextStyle(
          //         color: Color(0xFFF5ECD7),
          //         fontSize: 15,
          //         fontWeight: FontWeight.w700,
          //         letterSpacing: 1.5,
          //       ),
          //     ),
          //   ],
          // ),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────
class _FloatingEmoji {
  final String emoji;
  final double x, y, size, speed, phase, amplitude;

  _FloatingEmoji({
    required this.emoji,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.amplitude,
  });
}