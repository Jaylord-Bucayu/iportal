import 'package:flutter/material.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final String _correctPin = "1234"; // Define the correct PIN
  final List<String> _pin = ["", "", "", ""]; // Tracks the entered PIN
  int _currentIndex = 0; // Tracks the current input position

  // Function to handle number input
  void _onNumberPressed(String number) {
    if (_currentIndex < 4) {
      setState(() {
        _pin[_currentIndex] = number;
        _currentIndex++;
      });

      // Check if the PIN is complete
      if (_currentIndex == 4) {
        _validatePin();
      }
    }
  }

  // Function to handle delete/backspace
  void _onDeletePressed() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _pin[_currentIndex] = "";
      });
    }
  }

  // Function to validate the entered PIN
  void _validatePin() {
    String enteredPin = _pin.join(""); // Combine the PIN digits into a string
    if (enteredPin == _correctPin) {
      // Navigate to the home screen
      Navigator.pushNamed(context, 'time_in_out');
    } else {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incorrect PIN. Please try again."),
        ),
      );

      // Clear the PIN for re-entry
      setState(() {
        _pin.fillRange(0, 4, "");
        _currentIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/images/dswd-plipinas.png', // Replace with your image asset path
                  fit: BoxFit.cover,
                  height: 150, // Adjust size if needed
                ),
                const SizedBox(height: 20),
                const Text(
                  "Enter your pin number",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87),
                ),
                const SizedBox(height: 20),
                // PIN Input Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      width: 15,
                      height: 15,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _pin[index].isNotEmpty
                            ? Colors.primaries[4]
                            : Colors.grey[300],
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
              ],
            ),
            const Spacer(), // Push keypad to the bottom
            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Three buttons per row
                  mainAxisSpacing: 1, // Reduce spacing between rows
                  crossAxisSpacing: 1, // Reduce spacing between columns
                  childAspectRatio: 1, // Keep buttons square
                ),
                itemBuilder: (context, index) {
                  if (index == 9) {
                    // Biometric Placeholder
                    return GestureDetector(
                      onTap: () {
                        // Add biometric functionality here
                        print("Biometric authentication triggered");
                      },
                      child:
                          const Icon(Icons.fingerprint, size: 24, color: Colors.black),
                    );
                  } else if (index == 11) {
                    // Backspace/Delete Button
                    return GestureDetector(
                      onTap: _onDeletePressed,
                      child: const Icon(Icons.backspace_outlined,
                          size: 24, color: Colors.black),
                    );
                  } else {
                    // Digit Buttons
                    String digit = index == 10 ? "0" : "${index + 1}";
                    return GestureDetector(
                      onTap: () => _onNumberPressed(digit),
                      child: Container(
                        margin: const EdgeInsets.all(0),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.white,
                        ),
                        child: Text(
                          digit,
                          style: const TextStyle(
                            fontSize: 24, // Smaller font size
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

