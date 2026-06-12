import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ViewPassSlipScreen extends StatelessWidget {
  const ViewPassSlipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.primaries[4], // bright background
      appBar: AppBar(
        backgroundColor: Colors.primaries[4],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Pass Slip QR",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // QR CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage("assets/images/kap.jpg"),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    "Landbank Account Creation",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Sep 21 2023",
                    style: TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 16),

                  QrImageView(
                    data:
                        "https://drive.google.com/file/d/1iWBJPw-ktWkz1nBYjR592YNgcxgKYwbz/view",
                    version: QrVersions.auto,
                    size: 200,
                    embeddedImage: const AssetImage("assets/images/bago.png"),
                    embeddedImageStyle: const QrEmbeddedImageStyle(
                      size: Size(50, 50),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Scan the QR code to verify the pass slip",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Approval of the Head",
                      style: TextStyle(
                        color: Colors.primaries[4],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),


            // DETAILS CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Out / In row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          Text("Out: 08:10 AM",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                        
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          
                          SizedBox(height: 4),
                          Text("In: 09:20 AM",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                        
                        ],
                      ),
                    ],
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
