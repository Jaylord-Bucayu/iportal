// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:flutter_pdfview/flutter_pdfview.dart';
// import 'dart:io';

// class PdfAssetViewer extends StatefulWidget {
//   final String assetPath;
//   const PdfAssetViewer({super.key, required this.assetPath});

//   @override
//   State<PdfAssetViewer> createState() => _PdfAssetViewerState();
// }

// class _PdfAssetViewerState extends State<PdfAssetViewer> {
//   String? localPath;

//   @override
//   void initState() {
//     super.initState();
//     copyAssetToLocal();
//   }

//   Future<void> copyAssetToLocal() async {
//     final bytes = await rootBundle.load(widget.assetPath);
//     final dir = await Directory.systemTemp.createTemp();
//     final file = File('${dir.path}/temp.pdf');
//     await file.writeAsBytes(bytes.buffer.asUint8List());

//     setState(() {
//       localPath = file.path;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("PDF Viewer")),
//       body: localPath == null
//           ? const Center(child: CircularProgressIndicator())
//           : PDFView(
//               filePath: localPath,
//               enableSwipe: true,
//               swipeHorizontal: true,
//               autoSpacing: true,
//               pageFling: true,
//             ),
//     );
//   }
// }
