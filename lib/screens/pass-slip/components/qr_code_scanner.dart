// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:shop/route/screen_export.dart';

// class QrScannerScreen extends StatefulWidget {
//   const QrScannerScreen({Key? key}) : super(key: key);

//   @override
//   State<QrScannerScreen> createState() => _QrScannerScreenState();
// }

// class _QrScannerScreenState extends State<QrScannerScreen> {
//   final MobileScannerController controller = MobileScannerController();
//   bool _isProcessing = false; // ✅ Prevents multiple triggers

//   Future<void> _fetchPassSlipData(String url) async {
//     try {
//       // ✅ Show loading dialog
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );

//       final response = await http.get(Uri.parse(url));

//       // ✅ Remove loading dialog before proceeding
//       if (mounted) Navigator.pop(context);

//       if (response.statusCode == 200) {
//         final jsonResponse = json.decode(response.body);

//         if (jsonResponse['success'] == true &&
//             jsonResponse['data'] != null &&
//             jsonResponse['data'].isNotEmpty) {
//           final Map<String, dynamic> passSlip =
//               Map<String, dynamic>.from(jsonResponse['data'][0]);

//           if (mounted) {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) =>
//                     QrApprovalInfoScreen(scannedData: passSlip),
//               ),
//             ).then((_) {
//               // reset scanner state when back
//               setState(() => _isProcessing = false);
//             });
//           }
//         } else {
//           _showError("Invalid response from server");
//         }
//       } else {
//         _showError("Error: ${response.statusCode}");
//       }
//     } catch (e) {
//       if (mounted) Navigator.pop(context); // ensure modal is closed on error
//       _showError("Failed to fetch data: $e");
//     }
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//     setState(() => _isProcessing = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         title: Text(
//           'Scan QR Code',
//           style: TextStyle(color: Colors.primaries[4]),
//         ),
//         centerTitle: true,
//         iconTheme: IconThemeData(color: Colors.primaries[4]),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.flip_camera_android),
//             onPressed: () => controller.switchCamera(),
//           ),
//           IconButton(
//             icon: const Icon(Icons.flash_on),
//             onPressed: () => controller.toggleTorch(),
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           /// ✅ Camera preview
//           MobileScanner(
//             controller: controller,
//             onDetect: (capture) {
//               if (_isProcessing) return; // prevent multiple scans
//               final List<Barcode> barcodes = capture.barcodes;

//               for (final barcode in barcodes) {
//                 final String? value = barcode.rawValue;
//                 if (value != null && value.startsWith("http")) {
//                   setState(() => _isProcessing = true);
//                   debugPrint("QR Found! $value");
//                   _fetchPassSlipData(value); // call API
//                   break;
//                 }
//               }
//             },
//           ),

//           /// Overlay square
//           Center(
//             child: Container(
//               width: 250,
//               height: 250,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.white, width: 3),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
