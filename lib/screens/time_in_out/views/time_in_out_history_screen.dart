import 'package:flutter/material.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> transactions = [
    {"date": "30 Nov 2024", "clock_in": "09:10", "clock_out": "18:20"},
    {"date": "29 Nov 2024", "clock_in": "09:05", "clock_out": "18:15"},
    {"date": "28 Nov 2024", "clock_in": "08:55", "clock_out": "18:30"},
    {"date": "27 Nov 2024", "clock_in": "09:00", "clock_out": "18:25"},
    {"date": "27 Nov 2024", "clock_in": "09:00", "clock_out": "18:25"},
    {"date": "27 Nov 2024", "clock_in": "09:00", "clock_out": "18:25"},
    {"date": "27 Nov 2024", "clock_in": "09:00", "clock_out": "18:25"},
    {"date": "27 Nov 2024", "clock_in": "09:00", "clock_out": "18:25"},
    {"date": "27 Nov 2024", "clock_in": "09:00", "clock_out": "18:25"},
    
  ];

  TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Clock In/Out History",style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.primaries[4],
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            color: Colors.white,
            child: Row(
              
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: "Last 30 days",
                  items: ["Last 7 days", "Last 30 days", "Last 90 days"]
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    // Handle filter change
                  },
                ),
                DropdownButton<String>(
                  value: "All Types",
                  items: ["All Types", "Clock In", "Clock Out"]
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    // Handle type change
                  },
                ),
              ],
            ),
          ),

          // Transaction History Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal:12,vertical: 16),
            alignment: Alignment.centerLeft,
            child: const Text(
              "Transaction History",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

        
          // Transactions List
          Expanded(
        
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 1.0),
                   shape: const RoundedRectangleBorder( // Remove border radius
                    side: BorderSide.none, // Optional: remove border entirely
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: Colors.primaries[4],
                      size: 20,
                    ),
                    title: Text(
                      transaction["date"],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Clock In: ${transaction["clock_in"]} | Clock Out: ${transaction["clock_out"]}",
                      style: const TextStyle(color: Colors.grey,fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

