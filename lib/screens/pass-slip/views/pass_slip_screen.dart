import 'package:flutter/material.dart';
import 'package:shop/screens/pass-slip/components/qr_code_scanner.dart';
import 'view_pass_slip_screen.dart'; // bottom sheet screen

class PassSlipScreen extends StatelessWidget {
  const PassSlipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.primaries[4],
        title: const Text(
          'Pass Slip',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            tooltip: "Scan QR Code",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QrScannerScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
Padding(
  padding: const EdgeInsets.only(top: 15.0, left: 20.0, right: 20.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Left side (Title + Description stacked)
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Total Hours Pass slip',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2), // small gap
          Text(
            'Display total hours rendered for this month',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12.0,
              height: 1.2, // tighter line height
            ),
          ),
        ],
      ),

      // Right side (Button with Icon + Text)
SizedBox(
  height: 32, // increase overall height
  child: TextButton.icon(
    style: TextButton.styleFrom(
      backgroundColor: Colors.grey.shade100,
      foregroundColor: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // more padding
      minimumSize: const Size(0, 0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
    ),
    onPressed: () {
      Navigator.pushNamed(context, 'apply_pass_slip');
    },
    icon: const Icon(
  Icons.add,
  size: 18, // bigger size for more weight
  color: Colors.black87, // darker color also looks heavier
), // larger icon
    label: const Text(
      "Apply",
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold), // larger text
    ),
  ),
),




    ],
  ),
)
,            _buildTopSection(context),
              Expanded(
                child: Container(
                  color: Colors.grey[100],
                  padding: const EdgeInsets.only(top: 12),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    children: [
                        
                      Container(
                        padding: EdgeInsets.only(left: 28.0),
                        color: Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Transactions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black
                              ),
                            ),
                           IconButton(
                          icon: const Icon(Icons.calendar_month,color:Colors.black),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              isScrollControlled: true,
                              shape: null, // remove border radius
                              builder: (BuildContext context) {
                                return SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.3, // fills 40% of screen height
                                  width: double.infinity, // full width
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header: Select Date + Close (X)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                        'Select Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                                            ),
                                            IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 0.5),
                        
                                      // Options
                                      Expanded(
                                        child: ListView(
                                          children: [
                                            ListTile(
                        title: const Text('Last 7 days'),
                        onTap: () => Navigator.pop(context, 'Last 7 days'),
                                            ),
                                            ListTile(
                        title: const Text('Last 30 days'),
                        onTap: () => Navigator.pop(context, 'Last 30 days'),
                                            ),
                                            const Divider(height: 1),
                                            ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Pick the Date Range'),
                        onTap: () {
                          Navigator.pop(context, 'Pick Range');
                          // TODO: Open your date range picker
                        },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ).then((selected) {
                              if (selected != null) {
                                print('Selected: $selected');
                              }
                            });
                          },
                        )
                        
                          ],
                        ),
                      ),
 
                      _buildSavingCard(
                        context,
                        icon: Icons.directions_car,
                        title: 'Landbank Account Creation',
                        monthlySaving: 'January 20, 2025',
                      ),
                      _buildSavingCard(
                        context,
                        icon: Icons.home,
                        title: 'Pag-ibig MPL',
                        monthlySaving: '500.00',
                      ),
                      _buildSavingCard(
                        context,
                        icon: Icons.flight,
                        title: 'GSIS',
                        monthlySaving: '500.00',
                      ),
                      _buildSavingCard(
                        context,
                        icon: Icons.people,
                        title: 'SWEAP Loan',
                        monthlySaving: '500.00',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Bottom Card → opens draggable bottom sheet
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                 Navigator.pushNamed(context, 'apply_pass_slip');
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Landbank Account Creation",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        SizedBox(height: 4),
                        Text("Personal",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Total Duration",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        SizedBox(height: 4),
                        Text("14 mins",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Top Section
  Widget _buildTopSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoCard(
                title: "Personal",
                value: "10 mins",
                color: Colors.green,
              
                 imagePath: "assets/images/personal.png"
              ),
              _buildInfoCard(
                title: "Official",
                value: "2 hrs",
                color: Colors.red,
              
                imagePath: "assets/images/official.png"
              ),
            ],
          ),
          // const SizedBox(height: 12),
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: Colors.primaries[4],
          //       elevation: 0,
          //       padding:
          //           const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //     ),
          //     onPressed: () {
          //       Navigator.pushNamed(context, 'apply_pass_slip');
          //     },
          //     child: const Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //       children: [
          //         Text(
          //           "Add New Transaction",
          //           style: TextStyle(
          //             color: Colors.white,
          //             fontWeight: FontWeight.bold,
          //             fontSize: 12,
          //           ),
          //         ),
          //         Icon(Icons.arrow_forward, color: Colors.white),
          //       ],
          //     ),
          //   ),
          // ),
        
        ],
      ),
    );
  }

Widget _buildInfoCard({
  required String title,
  required String value,
  required Color color,
  required String imagePath, // use an image instead of icon
}) {
  return Expanded(
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        children: [
          // Text content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Overlapping image on the right
          Positioned(
            right: -25,
            top: 0,
            bottom: 0,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              width: 80, // adjust size as needed
            ),
          ),
        ],
      ),
    ),
  );
}

  // 🔹 Saving Card
  Widget _buildSavingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String monthlySaving,
  }) {
    return InkWell(
      onTap: () {
       Navigator.pushNamed(context, 'view_pass_slip');
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.only(bottom: 2),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // CircleAvatar(
              //   backgroundColor: Colors.grey[200],
              //   child: Icon(icon, color: Colors.black),
              // ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(color: Colors.black, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(monthlySaving,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
