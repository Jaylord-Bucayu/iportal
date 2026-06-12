import 'package:flutter/material.dart';
import 'package:shop/screens/pass-slip/api/pass_slip_service.dart';

class ApplyPassSlipScreen extends StatefulWidget {
  const ApplyPassSlipScreen({super.key});

  @override
  State<ApplyPassSlipScreen> createState() => _ApplyPassSlipScreenState();
}

class _ApplyPassSlipScreenState extends State<ApplyPassSlipScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTransaction;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();

  final List<Map<String, String>> _transactions = [
    {
      'title': 'Official',
      'subtitle': 'For official business purposes.',
      'asset': 'assets/images/official.png'
    },
    {
      'title': 'Personal',
      'subtitle':
          'For personal reasons. All time consumed will be deducted from your salary.',
      'asset': 'assets/images/personal.png'
    },
  ];

void _submitApplication() async {
  if (_formKey.currentState!.validate() && _selectedTransaction != null) {
    final passSlipApplication = {
      'transaction': _selectedTransaction,
      'start_date': _startDate?.toIso8601String(),
      'end_date': _endDate?.toIso8601String(),
      'reason': _reasonController.text,
    };

    // ✅ Call Laravel API
    bool success = await PassSlipService.createPassSlip(passSlipApplication);

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    "assets/images/okay.png",
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Success",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your pass slip has been submitted successfully!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.primaries[4],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Okay",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          );
        },
      );

      // Reset form
      _formKey.currentState!.reset();
      _selectedTransaction = null;
      _startDate = null;
      _endDate = null;
      _reasonController.clear();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit pass slip!')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select transaction type!')),
    );
  }
}

  Widget _buildOptionCard(String title, String subtitle, String asset) {
    final isSelected = _selectedTransaction == title;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTransaction = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.grey.shade400 : Colors.grey.shade300,
            width: isSelected ? 1 : 1,
          ),
          color: isSelected ? Colors.grey.shade100 : Colors.white,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                asset,
                width: 40,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),

            // Title + Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.primaries[4] : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Application for Pass-slip',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Header: Title + Image
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Pass-slip Application',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Fill out the form below to request a pass slip for official or personal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right: Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        "assets/images/passslip.png",
                        width: 160,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Transaction Section
                const Text(
                  'Nature of Transaction',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87
                  ),
                ),
                const SizedBox(height: 8),

                Column(
                  children: _transactions
                      .map((t) => _buildOptionCard(
                          t['title']!, t['subtitle']!, t['asset']!))
                      .toList(),
                ),

                const SizedBox(height: 24),

                // Purpose
                const Text(
                  'Purpose',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your purpose',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty
                          ? 'Purpose is required'
                          : null,
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.primaries[4],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Submit Application',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
