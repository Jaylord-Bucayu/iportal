import 'package:flutter/material.dart';

const Map<int, String> leaveTypeNames = {
  1: 'Vacation Leave',
  2: 'Sick Leave',
  3: 'Emergency Leave',
};

const Map<int, IconData> leaveTypeIcons = {
  1: Icons.beach_access_rounded,
  2: Icons.medical_services_rounded,
  3: Icons.warning_amber_rounded,
};

const Map<int, Color> leaveTypeColors = {
  1: Colors.black,
  2: Color(0xFF00A400),
  3: Color(0xFFE2420E),
};

final Map<String, Map<String, dynamic>> leaveConfig = {
  'Vacation Leave': {
    'image': 'assets/images/tent.png',
    'color': Colors.black,
  },
  'Sick Leave': {
    'image': 'assets/images/face-with-thermometer.png',
    'color': Colors.yellow,
  },
  'Emergency Leave': {
    'image': 'assets/images/emergency.png',
    'color': Colors.orange,
  },
};


Widget leaveIconCard(String type,double w, double h) {
  final config = leaveConfig[type]!;

  return Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: config['color'].withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        config['image'],
        fit: BoxFit.contain,
      ),
    ),
  );
}
