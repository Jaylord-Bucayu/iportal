import 'package:flutter/material.dart';

class LoanHomeScreen extends StatelessWidget {
  const LoanHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.primaries[4],
        title: const Text('Loan Manager', style: TextStyle(color: Colors.white)),
        centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
               Navigator.pushNamed(context, 'loan');
            },
          ),
        ],
      ),
      body: Column(
        
        children: [
          // Total Savings
          Container(
            width: double.infinity,
            color: Colors.primaries[4],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'TOTAL LOAN BALANCE',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  '24,154.32',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              SizedBox(height: 8),
              ],
            ),
          ),
         
         
          const SizedBox(height: 12),
          // Tabs (Active, Collected, Complete)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTabButton('Active', true),
                _buildTabButton('Collected', false),
                _buildTabButton('Completed', false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Saving Items List
          Expanded(
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.only(top: 12),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSavingCard(
                    context,
                    icon: Icons.directions_car,
                    title: 'Car Loan',
                    current: '20,000.00',
                    monthlySaving: '500.00',
                    target: '43,900.00',
                    progress: 0.45,
                  ),
                  _buildSavingCard(
                    context,
                    icon: Icons.home,
                    title: 'Pag-ibig MPL',
                    current: '850.00',
                    monthlySaving: '500.00',
                    target: '1,200.00',
                    progress: 0.71,
                  ),
                  _buildSavingCard(
                    context,
                    icon: Icons.flight,
                    title: 'GSIS',
                    current: '500.00',
                    monthlySaving: '500.00',
                    target: '1,000.00',
                    progress: 0.5,
                  ),
                  _buildSavingCard(
                    context,
                    icon: Icons.people,
                    title: 'SWEAP Loan',
                    current: '500.00',
                    monthlySaving: '500.00',
                    target: '1,000.00',
                    progress: 0.24,
                  ),
                ],
              ),
            ),
          ),
        
        ],
      ),
      // Floating Action Button
     
    );
  }

  // Helper method for tabs
  Widget _buildTabButton(String title, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Helper method for saving cards
  Widget _buildSavingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String current,
    required String monthlySaving,
    required String target,
    required double progress,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Icon
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Icon(icon, color: Colors.black),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monthly saving: $monthlySaving',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar and Current/Target Text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target $target',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  color: Colors.red[600],
                  minHeight: 6,
                ),
              ],
            ),
          
          ],
        ),
      ),
    );
  }
}
