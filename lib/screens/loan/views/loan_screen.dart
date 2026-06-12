import 'package:flutter/material.dart';

class LoanScreen extends StatelessWidget {
  const LoanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Apply for a Loan',style: TextStyle(color:Colors.white),),
        backgroundColor: Colors.primaries[4], // Customize as per your theme
        iconTheme: const IconThemeData(color: Colors.white),
       
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://via.placeholder.com/400x150', // Replace with actual image URL
                  fit: BoxFit.cover,
                  height: 150,
                  width: double.infinity,
                ),
              ),
            ),
            // Title and Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose loan type you want to apply',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Local Transfer Card
                  GestureDetector(
                    onTap: () {
                      // Add navigation or action logic here
                    },
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                     shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.account_balance,
                          color: Colors.primaries[4],
                          size: 30,
                        ),
                        title: const Text(
                          'Government',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Add deductions to your account like Pag-ibig MPL.',
                        ),
                      ),
                    ),
                  ),

                  // International Transfer Card
                  GestureDetector(
                    onTap: () {
                      // Add navigation or action logic here
                    },
                    child: Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.public,
                          color: Colors.primaries[4],
                          size: 30,
                        ),
                        title: const Text(
                          'Private',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Apply for a loan from private lending companies.',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
