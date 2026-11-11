import 'package:flutter/material.dart';

class HomeBanner extends StatelessWidget {
  /// Time-based greeting, e.g. "Good Morning" (passed from parent).
  final String name;

  /// The user's actual display name, e.g. "Juan Dela Cruz".
  final String email;

  /// Local asset path for the banner image, e.g. "assets/logo/bago-p.png".
  final String imageUrl;

  const HomeBanner({
    super.key,
    required this.name,
    required this.email,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final firstName =
    email.trim().isNotEmpty ? email.trim().split(' ').first : 'Guest';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: badge + title + subtitle ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // "Board Certified" style pill/label
                const Text(
                  'Welcome to DSWD FO2 IPORTAL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 8),

                // Big bold name (like "Dr. Sophia Miller")
                Text(
                  'Hi $firstName',
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    color: Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 10),

                // Time-based greeting (like "Dermatologist")
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 2),

                // Small gray line (like "California Skin Clinic")
                const Text(
                  'DSWD Field Office II',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // ── Right: circular image with ring + badge ──
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Decorative light-blue ring behind the avatar
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFDCEBFF),
                      width: 6,
                    ),
                  ),
                ),

                // Circular avatar image, inset from the ring
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipOval(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Small blue badge/checkmark, bottom-right of the avatar
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}