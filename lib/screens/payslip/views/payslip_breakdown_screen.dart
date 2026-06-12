import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shop/screens/payslip/components/printPdf.dart';
import 'package:file_saver/file_saver.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import '../../../constants.dart';

class PayslipBreakdownScreen extends StatefulWidget {
  final String month;
  final int year;

  const PayslipBreakdownScreen({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<PayslipBreakdownScreen> createState() =>
      _PayslipBreakdownScreenState();
}

class _PayslipBreakdownScreenState extends State<PayslipBreakdownScreen> {
  Map<String, dynamic>? _payslipData;
  bool _loading = false;
  int _selectedIndex = 0;
  bool _showNetIncome = true; // add this in your State class

  @override
  void initState() {
    super.initState();
    _fetchPayslipData();
  }

 Future<void> _fetchPayslipData() async {
  setState(() => _loading = true);
  try {
    final response = await http.post(
      Uri.parse('https://172.31.16.50/api/payslip-by-id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'staff_id': 215462,
        'period_month': widget.month,  // <-- dynamic
        'period_year': widget.year.toString(),  // <-- dynamic
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        _payslipData =
            (json['data'] as List).isNotEmpty ? json['data'][0] : null;
      });

    } else {
      debugPrint("API Error: ${this.widget.month} ${this.widget.year} ${response.statusCode} ${response.body}");
    }
  } catch (e) {
    debugPrint("Error fetching payslip: $e");
  } finally {
    setState(() => _loading = false);
  }
}

  Future<pw.MemoryImage> _loadLogoImage() async {
    final ByteData logoData =
        await rootBundle.load('assets/images/dswd-pilipinas.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    return pw.MemoryImage(logoBytes);
  }

  Future<void> _handleDownload(BuildContext context) async {
    if (_payslipData == null) {
      _showSnackbar(context, "No payslip data available");
      return;
    }
      final int year = widget.year;        // year selected from UI
      final int monthIndex = _selectedIndex; // 1–12
      final String monthName = DateFormat.MMMM().format(
        DateTime(year, monthIndex),
      );

// last day of the month (30 / 31 / 28 / 29)
final int lastDay = DateTime(year, monthIndex + 1, 0).day;

final String dateRange = '1 $monthName $year - $lastDay $monthName $year';


    try {
      final logoImage = await _loadLogoImage();
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => buildPayslip(
            logoImage,
            _payslipData!,
            monthName,
            year,
            dateRange
          ),
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      const fileName = 'payslip-august-2025.pdf';

      if (kIsWeb || io.Platform.isAndroid || io.Platform.isIOS) {
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: pdfBytes,
          ext: 'pdf',
          mimeType: MimeType.pdf,
        );
      } else {
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Payslip PDF',
          fileName: fileName,
        );
        if (savePath != null) {
          final file = io.File(savePath);
          await file.writeAsBytes(pdfBytes);
          _showSnackbar(context, 'Payslip saved to $savePath');
          return;
        } else {
          _showSnackbar(context, 'Save canceled');
          return;
        }
      }

      _showSnackbar(context, 'Payslip saved successfully.');
    } catch (e) {
      debugPrint("Error saving PDF: $e");
      _showSnackbar(context, 'Failed to save PDF');
    }
  }

  Future<void> _handlePrint(BuildContext context) async {
    if (_payslipData == null) {
      _showSnackbar(context, "No payslip data available");
      return;
    }

  final int year = widget.year;        // year selected from UI
      final int monthIndex = _selectedIndex; // 1–12
      final String monthName = DateFormat.MMMM().format(
        DateTime(year, monthIndex),
      );

// last day of the month (30 / 31 / 28 / 29)
final int lastDay = DateTime(year, monthIndex + 1, 0).day;

final String dateRange = '1 $monthName $year - $lastDay $monthName $year';

    try {
      final logoImage = await _loadLogoImage();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final pdf = pw.Document();
          pdf.addPage(
            pw.Page(
              pageFormat: format.copyWith(
                marginTop: 20,
                marginBottom: 20,
                marginLeft: 20,
                marginRight: 20,
              ),
              build: (context) => buildPayslip(logoImage, _payslipData!, monthName,
            year,
            dateRange),
            ),
          );
          return pdf.save();
        },
      );
    } catch (e) {
      debugPrint("Error printing PDF: $e");
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildCategoryButtons() {
    final categories = ["All", "Contributions", "Loans", "Others"];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(categories.length, (index) {
          final isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedIndex = index);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.primaries[4] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
    appBar: AppBar(
  backgroundColor: Colors.white,
  title: Text('${widget.month} ${widget.year}',
      style: const TextStyle(color: Colors.black)),
  centerTitle: true,
  iconTheme: const IconThemeData(color: Colors.black),
),
body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [

                 _buildNetIncomeCard(),
                 
// Stack(
//   clipBehavior: Clip.none, // allows card to overflow outside the image
//   children: [
//     // Background image
//     Image.asset(
//       'assets/images/payslip.jpg',
//       height: 200,
//       width: double.infinity,
//       fit: BoxFit.fill,
//     ),

//     // Positioned income card overlapping the image
//     Positioned(
//       top: 0, // adjust to control overlap
//       left: 16,
//       right: 16,
//       child: _buildNetIncomeCard(),
//     ),
//   ],
// ),

// SizedBox(height: 12.0),
                _buildCategoryButtons(),
                Expanded(
                  child: Builder(
                    builder: (_) {
                      if (_selectedIndex == 0) {
                        final allItems = [
                          ...List<Map<String, dynamic>>.from(
                            (_payslipData?['deductions']?['contributions'] ??
                                []) as List,
                          ),
                          ...List<Map<String, dynamic>>.from(
                            (_payslipData?['deductions']?['loans'] ?? [])
                                as List,
                          ),
                          ...List<Map<String, dynamic>>.from(
                            (_payslipData?['deductions']?['others'] ?? [])
                                as List,
                          ),
                        ];
                        return _buildContributionList(allItems);
                      } else if (_selectedIndex == 1) {
                        return _buildContributionList(
                          List<Map<String, dynamic>>.from(
                            (_payslipData?['deductions']?['contributions'] ??
                                []) as List,
                          ),
                        );
                      } else if (_selectedIndex == 2) {
                        return _buildContributionList(
                          List<Map<String, dynamic>>.from(
                            (_payslipData?['deductions']?['loans'] ?? [])
                                as List,
                          ),
                        );
                      } else {
                        return _buildContributionList(
                          List<Map<String, dynamic>>.from(
                            (_payslipData?['deductions']?['others'] ?? [])
                                as List,
                          ),
                        );
                      }
                    },
                  ),
                ),
              
              ],
            ),
    );
  }

Widget _buildNetIncomeCard() {
  final netAmount = _payslipData != null
      ? (_payslipData!['net_amount'] is num
          ? (_payslipData!['net_amount'] as num).toStringAsFixed(2)
          : _payslipData!['net_amount'].toString())
      : '0.00';

  return Container(
    margin: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Stack(
      children: [
        // Background image (watermark)
        Positioned(
          top: 16,
          right: -16,
          child: Opacity(
            opacity: 0.8, // make it faint
            child: Image.asset(
              'assets/images/1k.png',
              height: 100,
              width: 110,
              fit: BoxFit.contain,
            ),
          ),
        ),

        // Card content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "TOTAL NET INCOME",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                
                ],
              ),
              const SizedBox(height: 12),

              // Net Income + visibility
              Row(
                children: [
                  Text(
                    _showNetIncome ? "\$$netAmount" : "******",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showNetIncome = !_showNetIncome;
                      });
                    },
                    child: Icon(
                      _showNetIncome
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.black54,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Quincena breakdown
              Row(
                children: [
                  Text(
                    "1st Q: ${_payslipData != null ? (_payslipData!['first_quincena'] is num ? (_payslipData!['first_quincena'] as num).toStringAsFixed(2) : _payslipData!['first_quincena'].toString()) : '0.00'}",
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "2nd Q: ${_payslipData != null ? (_payslipData!['second_quincena'] is num ? (_payslipData!['second_quincena'] as num).toStringAsFixed(2) : _payslipData!['second_quincena'].toString()) : '0.00'}",
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleDownload(context),
                      icon:  Icon(Icons.arrow_downward, size: 18,color: Colors.primaries[4],),
                      label:  Text("Download",style: TextStyle(color: Colors.primaries[4]),),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handlePrint(context),
                      icon:  Icon(Icons.print, size: 16,color: Colors.grey.shade700),
                      label: Text("Print",style: TextStyle(color: Colors.grey.shade700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _buildContributionList(List<Map<String, dynamic>> contributions) {
    if (contributions.isEmpty) {
      return const Center(child: Text("No data available"));
    }
    return ListView.builder(
      itemCount: contributions.length,
      itemBuilder: (context, index) {
        final item = contributions[index];
        final deductionName = item['deduction_name'] ?? '';
        final amount = item['amount'] ?? 0;
        final imagePath = DeductionIcons.assetFor(deductionName);

        return _PayslipLineItem(
          title: deductionName,
          amount: '- ${(amount is num ? amount : 0).toStringAsFixed(2)}',
          imagePath: imagePath,
        );
      },
    );
  }
}

class _PayslipLineItem extends StatelessWidget {
  final String title;
  final String amount;
  final String imagePath;

  const _PayslipLineItem({
    required this.title,
    required this.amount,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final isSvg = imagePath.toLowerCase().endsWith('.svg');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.3),
        ),
      ),
      child: Row(
        children: [
          if (imagePath.isNotEmpty)
            isSvg
                ? SvgPicture.asset(
                    imagePath,
                    width: 20,
                    height: 20,
                    placeholderBuilder: (context) => const Icon(
                      Icons.image_not_supported,
                      size: 20,
                      color: Colors.grey,
                    ),
                  )
                : Image.asset(
                    imagePath,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.home, size: 20, color: Colors.grey),
                  ),
          const SizedBox(width: 8),

          /// 👇 Expanded fixes overflow for text area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontSize: 12.0,
                  ),
                ),
                const Text(
                  'Government Service Insurance System Conso-Loan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w100,
                    color: Colors.grey,
                    fontSize: 10.0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          /// Amount stays fixed on right
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
