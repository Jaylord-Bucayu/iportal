import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:local_auth/local_auth.dart'; // For biometric authentication

class TimeInOutScreen extends StatefulWidget {
  const TimeInOutScreen({super.key});

  @override
  _TimeInOutPageState createState() => _TimeInOutPageState();
}

class _TimeInOutPageState extends State<TimeInOutScreen> {
  late String _currentTime;
  late String _currentDate;
  Timer? _timer;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('h:mm a').format(now); // 12-hour format
      _currentDate = DateFormat('EEEE, MMM d').format(now); // Full date
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _authenticate() async {
    bool isAuthenticated = true;

    try {
      isAuthenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to Clock In',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print('Authentication error: $e');
    }

    if (isAuthenticated) {
      // Show DraggableScrollableSheet after successful authentication
  showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grabber
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Top Text
              const Text(
                "Touch ID sensor to verify transaction",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please confirm your identity by using Touch ID\n"
                "to continue the transaction",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              // Fingerprint Icon
              const Icon(
                Icons.fingerprint,
                size: 80,
                color: Colors.black,
              ),
              const SizedBox(height: 16),
              // "Or Use PIN" Button
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, 'pin');
                },
                child: Text(
                  "Or Use PIN",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
              ),
              const Spacer(),
              // Cancel Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the sheet
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  },
);
} else {
      // Handle failed authentication
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication Failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Clock In/Out"),
        backgroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, 'time_in_out_history');
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Section
            Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  _currentTime,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentDate,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            // Clock-In Button
            Center(
              child: GestureDetector(
                onTap: _authenticate,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.primaries[4],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fingerprint,
                          color: Colors.white,
                          size: 40,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "CLOCK IN",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Location
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    "In Office range",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomInfo(Icons.access_time, "09:10", "Clock In"),
                  _buildBottomInfo(Icons.logout, "18:20", "Clock Out"),
                  _buildBottomInfo(Icons.timelapse, "8:20", "Working Hr's"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInfo(IconData icon, String time, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.primaries[4], size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
