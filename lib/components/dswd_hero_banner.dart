import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class DswdHeroBanner extends StatefulWidget {
  final String title;
  final String? subtitle;

  /// Pass the user's first name directly (already parsed). If you have a
  /// raw "LASTNAME, FIRSTNAME, MIDDLENAME" string instead, run it through
  /// `getFirstName()` before passing it in.
  final String? userName;

  /// e.g. "Good Morning", "Good Afternoon", "Good Evening". Defaults to
  /// "Good Day" if not provided.
  final String greeting;

  /// Network URL for the staff photo shown in the circular avatar.
  final String? imageUrl;

  const DswdHeroBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.userName,
    this.greeting = 'Good Day',
    this.imageUrl,
  });

  @override
  State<DswdHeroBanner> createState() => _DswdHeroBannerState();
}

class _DswdHeroBannerState extends State<DswdHeroBanner>
    with TickerProviderStateMixin {
  // Rotating shimmer ring around the avatar
  late final AnimationController _ringController;

  // Typewriter reveal, plays once on first load
  Timer? _typeTimer;
  int _greetingChars = 0;
  int _nameChars = 0;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startTypewriter();
  }

  void _startTypewriter() {
    final greeting = widget.greeting;
    final name = widget.userName ?? '';

    const step = Duration(milliseconds: 45);
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(step, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_greetingChars < greeting.length) {
          _greetingChars++;
        } else if (_nameChars < name.length) {
          _nameChars++;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant DswdHeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Replay the typewriter effect if the name or greeting actually changes.
    if (oldWidget.userName != widget.userName ||
        oldWidget.greeting != widget.greeting) {
      _greetingChars = 0;
      _nameChars = 0;
      _startTypewriter();
    }
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final greeting = widget.greeting;
    final name = widget.userName ?? '';
    final visibleGreeting = greeting.substring(0, _greetingChars.clamp(0, greeting.length));
    final visibleName = name.substring(0, _nameChars.clamp(0, name.length));

    return Container(
      width: double.infinity,
      height: 150,
      child: Stack(
        children: [
          // Background illustration
          Positioned.fill(
            child: Image.asset(
              'assets/images/dswd-banner.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // Text content
          Positioned(
            left: 24,
            top: 24,
            bottom: 24,
            child: SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.userName != null && widget.userName!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _ShimmerRingAvatar(
                          ringAnimation: _ringController,
                          imageUrl: widget.imageUrl,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                visibleGreeting,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                visibleName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (widget.title.isNotEmpty)
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),

                  if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar with a clean white backdrop and a soft border shadow.
class _ShimmerRingAvatar extends StatelessWidget {
  final Animation<double> ringAnimation;
  final String? imageUrl;

  const _ShimmerRingAvatar({
    required this.ringAnimation,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    const avatarRadius = 22.0;
    const backdropSize = (avatarRadius + 3) * 2; // white backdrop + border

    return Container(
      width: backdropSize,
      height: backdropSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: CircleAvatar(
          radius: avatarRadius,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
              ? NetworkImage(imageUrl!)
              : null,
          child: (imageUrl == null || imageUrl!.isEmpty)
              ? Icon(Icons.person, color: Colors.grey.shade400)
              : null,
        ),
      ),
    );
  }
}