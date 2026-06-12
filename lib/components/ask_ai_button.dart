import 'package:flutter/material.dart';

class FloatingAIButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;

  const FloatingAIButton({
    super.key,
    required this.onTap,
    this.label = 'IPortal AI',
  });

  @override
  State<FloatingAIButton> createState() => _FloatingAIButtonState();
}

class _FloatingAIButtonState extends State<FloatingAIButton>
    with TickerProviderStateMixin {

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  bool _showLabel = false;

  static const Color _success = Color(0xFF10B981);
  static const Color _gray900 = Color(0xFF1A202C);

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseAnim = CurvedAnimation(
      parent: _pulseCtrl,
      curve: Curves.easeOut,
    );

    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [

        // ── Tooltip ──
        AnimatedOpacity(
          opacity: _showLabel ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedSlide(
            offset: _showLabel ? Offset.zero : const Offset(0, 0.3),
            duration: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.only(right: 8, bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _gray900,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Button ──
        GestureDetector(
          onTapDown: (_) {
            _pressCtrl.forward();
            setState(() => _showLabel = true);
          },
          onTapUp: (_) {
            _pressCtrl.reverse();
            Future.delayed(const Duration(milliseconds: 80), () {
              if (mounted) setState(() => _showLabel = false);
              widget.onTap();
            });
          },
          onTapCancel: () {
            _pressCtrl.reverse();
            setState(() => _showLabel = false);
          },
          child: ScaleTransition(
            scale: _scaleAnim,
            child: SizedBox(
              width: 68,
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [

                  // ── Pulse ring ──
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) {
                      final scale = 1.0 + (_pulseAnim.value * 0.55);
                      final opacity =
                          (1.0 - _pulseAnim.value).clamp(0.0, 0.4);

                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.yellow.withOpacity(opacity),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // ── Soft glow ──
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) {
                      final v = (_pulseAnim.value + 0.4) % 1.0;
                      final scale = 1.0 + (v * 0.35);
                      final opacity = (1.0 - v).clamp(0.0, 0.2);

                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.yellow.withOpacity(opacity),
                          ),
                        ),
                      );
                    },
                  ),

                  // ── IMAGE WITH YELLOW BORDER ──
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.yellow, // ← changed here
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/bot/proud.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // ── Online dot ──
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _success,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _success.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
} 