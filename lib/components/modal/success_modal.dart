import 'package:flutter/material.dart';

class SuccessModal {
  /// Show a success modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    required String message,
    String? description,
    String? assetImage, // optional custom image
    VoidCallback? onDone, // optional action when done
  }) async {
    showModalBottomSheet(
      context: context,
      isDismissible: false,  // prevent tap outside
      enableDrag: false,     // prevent swipe down
      backgroundColor: Colors.transparent, // allows margin effect
      builder: (_) => Container(
        margin: const EdgeInsets.all(16), // margin around modal
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Asset image
            Image.asset(
              assetImage ?? 'assets/images/success.png', // default image if none provided
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),

            // Main message
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Optional description
            if (description != null)
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),

            // Done button
           SizedBox(
  width: double.infinity,
  child: OutlinedButton(
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white, // button fill color (optional)
      side: BorderSide(
        color: Colors.grey.shade300, // border color
        width: 1.5, // border thickness
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // optional radius
      ),
    ),
    onPressed: () {
      Navigator.of(context).pop(); // close modal
      if (onDone != null) onDone(); // optional callback
    },
    child: const Text(
      'Done',
      style: TextStyle(color: Colors.black87), // text color
    ),
  ),
),
          ],
        ),
      ),
    );
  }
}