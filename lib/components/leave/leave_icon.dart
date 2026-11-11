import 'package:flutter/material.dart';

const Map<int, String> leaveTypeNames = {
  1: 'Vacation Leave',
  2: 'Sick Leave',
  3: 'Special Privilege Leave',
  16: 'Emergency Leave',
};

const Map<int, IconData> leaveTypeIcons = {
  1: Icons.beach_access_rounded,
  2: Icons.medical_services_rounded,
  3: Icons.star_rounded, // added
  16: Icons.warning_amber_rounded,
};

const Map<int, Color> leaveTypeColors = {
  1: Colors.black,
  2: Color(0xFF00A400),
  3: Color(0xFF7C3AED), // added
  16: Color(0xFFE2420E),
};

class LeaveVisual {
  final String image;
  final Color color;
  const LeaveVisual({required this.image, required this.color});
}

const _defaultVisual = LeaveVisual(
  image: '',
  color: Colors.black,
);

const Map<String, LeaveVisual> leaveConfig = {
  'Vacation Leave': LeaveVisual(
    image: 'assets/images/tent.png',
    color: Colors.black,
  ),
  'Sick Leave': LeaveVisual(
    image: 'assets/images/face-with-thermometer.png',
    color: Colors.yellow,
  ),
  'Special Privilege Leave': LeaveVisual(
    image: 'assets/images/spl.png',
    color: Colors.green,
  ),
  'Emergency Leave': LeaveVisual(
    image: 'assets/images/emergency.png',
    color: Colors.orange,
  ),
};

/// Finds config by exact name, then by loose match
/// (handles "Special Privilege", "SPL", "special privilege leave", etc.)
LeaveVisual _resolveVisual(String type) {
  final exact = leaveConfig[type];
  if (exact != null) return exact;

  final t = type.trim().toLowerCase();

  if (t == 'spl' || t.contains('special privilege')) {
    return leaveConfig['Special Privilege Leave']!;
  }
  if (t.contains('vacation') || t == 'vl') {
    return leaveConfig['Vacation Leave']!;
  }
  if (t.contains('sick') || t == 'sl') {
    return leaveConfig['Sick Leave']!;
  }
  if (t.contains('emergency') || t == 'el') {
    return leaveConfig['Emergency Leave']!;
  }
  return _defaultVisual;
}

Widget leaveIconCard(String type, double w, double h) {
  final config = _resolveVisual(type);

  return Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: config.color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: config.image.isEmpty
          ? Icon(Icons.event_note_rounded, color: config.color)
          : Image.asset(
        config.image,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.event_note_rounded, color: config.color),
      ),
    ),
  );
}