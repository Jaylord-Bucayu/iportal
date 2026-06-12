import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

pw.Widget buildDeductionRow(dynamic label, dynamic amount) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Expanded(
        child: pw.Text(
          label.toString(),
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      pw.Text(
        amount is num ? amount.toStringAsFixed(2) : amount.toString(),
        style: const pw.TextStyle(fontSize: 8),
      ),
    ],
  );
}


pw.Widget buildPayslip(pw.ImageProvider logoImage,data,monthName,year,monthIndex) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(20),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
    pw.Row(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  children: [
    // Logo on the left
    pw.Image(logoImage, width: 100, height: 90),
    pw.SizedBox(width: 10),
    // Department information in the center
    pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Department of Social Welfare and Development Field Office II',
            textAlign: pw.TextAlign.left,
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '#3 Dalan na Pagayaya, Regional Government Center, Carig, Tuguegarao City',
            textAlign: pw.TextAlign.left,
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 5),
        ],
      ),
    ),
  ],
),
pw.SizedBox(height: 10),

// Centered Title
pw.Center(
  child: pw.Text(
   '${monthName} ${monthIndex}, ${year} PAYSLIP',
    textAlign: pw.TextAlign.center,
    style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue),
  ),
),



        pw.SizedBox(height: 10),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left side: Employee Info
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Employee: ${data['staff_name']}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Designation: ${data['position_name']}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Salary: ${data['sg_amount']}',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),

            // Right side: Net Pay
            pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end, // right align
            children: [
              pw.Text(
                'Employee Net Pay',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '${data['net_amount']}',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          )

          ],
        ),

        // Employee Info

        pw.SizedBox(height: 20),

        // Earnings and Deductions
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Earnings
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    color: PdfColors.grey300,
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'EARNINGS',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 8),
                    ),
                  ),
                  buildDeductionRow('Basic Salary', data['sg_amount']),
                  // buildDeductionRow('Premium', '2,000.00')
                ],
              ),
            ),
            pw.SizedBox(width: 30),
            // Deductions
    pw.Expanded(
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        color: PdfColors.grey300,
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          'DEDUCTIONS',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 8,
          ),
        ),
      ),
      pw.SizedBox(height: 4),

      // Loop through contributions
      ...List.generate(
        (data['deductions']['contributions'] as List).length,
        (index) {
          final contribution = data['deductions']['contributions'][index];
          return buildDeductionRow(
            contribution['deduction_name'].toString(),
            (contribution['amount'] as num).toDouble().toStringAsFixed(2),
          );
        },
      ),

      // Loop through loans
      ...List.generate(
        (data['deductions']['loans'] as List).length,
        (index) {
          final loan = data['deductions']['loans'][index];
          return buildDeductionRow(
            loan['deduction_name'].toString(),
            (loan['amount'] as num).toDouble().toStringAsFixed(2),
          );
        },
      ),

      // Loop through others
      ...List.generate(
        (data['deductions']['others'] as List).length,
        (index) {
          final other = data['deductions']['others'][index];
          return buildDeductionRow(
            other['deduction_name'].toString(),
            (other['amount'] as num).toDouble().toStringAsFixed(2),
          );
        },
      ),
    ],
  ),
),
],
        ),
        pw.SizedBox(height: 30),

        // Totals
        pw.Column(
          children: [
            pw.Divider(thickness: 0.5), // This is your "HR" line
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
               pw.Text(
                  data['amount_earned'] is num
                      ? (data['amount_earned'] as num).toStringAsFixed(2)
                      : data['amount_earned'].toString(),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),

              pw.Text(
                  data['total_deductions'] is num
                      ? (data['total_deductions'] as num).toStringAsFixed(2)
                      : data['total_deductions'].toString(),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),

              ],
            ),
          ],
        ),

        pw.SizedBox(height: 15),
        pw.Text('First Net Pay: ${data['first_quincena']}',
            style: const pw.TextStyle(fontSize: 8)),
        pw.Text('Second Net Pay: ${data['second_quincena']}',
            style: const pw.TextStyle(fontSize: 8)),

        pw.SizedBox(height: 30),

        pw.Text('Remarks:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 5,
            )),
        pw.Text('Late counts:', style: const pw.TextStyle(fontSize: 5)),
        pw.Text('Absent counts:', style: const pw.TextStyle(fontSize: 5)),
        pw.Text('Unearned counts: 0.00',
            style: const pw.TextStyle(fontSize: 5)),

        pw.SizedBox(height: 30),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            children: [
              // Signatory line at the top
              pw.Container(
                height: 1,
                width: 150, // You can adjust the width as needed
                color: const PdfColor.fromInt(0xFF000000), // Black line color
              ),
              pw.SizedBox(height: 5), // Space between the line and text
              pw.Text('Atty. JUAN ZALUN',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text('Chief Administrative Officer/Chief HRMDD',
                  style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
      ],
    ),
  );
}
