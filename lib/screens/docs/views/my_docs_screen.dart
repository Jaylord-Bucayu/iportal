import 'package:flutter/material.dart';

class MyDocumentsScreen extends StatelessWidget {
  const MyDocumentsScreen({super.key});

  final List<Map<String, String>> documents = const [
    {
      "title": "Passport",
      "number": "00000000",
      "image": "assets/images/peso.png"
    },
    {
      "title": "Foreign Passport",
      "number": "XX000000",
      "image": "assets/foreign_passport.png"
    },
    {
      "title": "Birth certificate",
      "number": "AA0000AA",
      "image": "assets/birth_certificate.png"
    },
    {
      "title": "Military ID",
      "number": "M0000000",
      "image": "assets/military_id.png"
    },
    {
      "title": "ITIN",
      "number": "1234567890",
      "image": "assets/itin.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Documents"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Contacts"),
              Tab(text: "My Documents"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const Center(child: Text("Contacts List Here")),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                itemCount: documents.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  if (index == documents.length) {
                    // Add Document button
                    return GestureDetector(
                      onTap: () {
                        // handle add
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.add, size: 40),
                        ),
                      ),
                    );
                  }
                  final doc = documents[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + arrow
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(doc["title"]!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              const Icon(Icons.chevron_right, size: 18),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Number left, Image right
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Number: ${doc["number"]}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                if (doc["image"] != null)
                                  Image.asset(
                                    doc["image"]!,
                                    width: 80,
                                    height: 70,
                                    fit: BoxFit.contain,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
