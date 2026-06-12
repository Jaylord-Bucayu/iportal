import 'package:flutter/material.dart';
import 'package:shop/screens/leaves/components/LeaveDateSelector.dart';
import 'package:intl/intl.dart';

class LeaveDateBadges extends StatelessWidget {
  final List<LeaveDateItem> dates;

  const LeaveDateBadges({super.key, required this.dates});

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty) return const SizedBox();

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final d = dates[index];
          final month   = DateFormat('MMM').format(d.date);
          final day     = d.date.day;
          final weekday = DateFormat('E').format(d.date);
          final portion = d.portion.name.toUpperCase();

          return Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF111111), Color(0xFF3A3A3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Month
                Text(
                  month,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.60),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),

                // Day + weekday
                Text(
                  '$day $weekday',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                // Portion badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    portion,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.85),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}