import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/screens/payslip/views/payslip_breakdown_screen.dart'; // Keep if needed

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  _PayslipPageState createState() => _PayslipPageState();
}

class _PayslipPageState extends State<PayslipScreen> {
  late String _currentTime;
  late String _currentDate;
  Timer? _timer;
  final LocalAuthentication _auth = LocalAuthentication();

  final List<String> _months = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  int _selectedYear = DateTime.now().year;

  // ✅ Initialize _years immediately to avoid LateInitializationError
  final List<int> _years = List<int>.generate(
    DateTime.now().year - 2025 + 1,
    (index) => 2025 + index,
  );

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('h:mm a').format(now);
      _currentDate = DateFormat('EEEE, MMM d').format(now);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Function to get last 6 months
  List<DateTime> _getLastSixMonths() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = now.month - i;
      final yearAdjustment = month <= 0 ? ((month - 1) ~/ 12) : 0;
      final adjustedMonth = month > 0 ? month : 12 + month;
      final year = now.year + yearAdjustment;
      return DateTime(year, adjustedMonth, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final int currentMonthIndex = DateTime.now().month - 1;
    final String currentMonth = _months[currentMonthIndex];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Payslip"),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.black,
            tabs: [
              Tab(text: 'Current'),
              Tab(text: '6 months'),
              Tab(text: 'Year'),
            ],
          ),
        ),
        backgroundColor: Colors.grey.shade100,
        body: TabBarView(
          children: [
            // Tab 1: Current month
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(
                        vertical: 5.0, horizontal: 5.0),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.calendar_today,
                        color: Colors.primaries[4],
                        size: 30,
                      ),
                      title: Text(
                        currentMonth,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '01 ${currentMonth} ${DateTime.now().year} - ${DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day} ${currentMonth} ${DateTime.now().year}',
                        style: const TextStyle(fontSize: 12.0),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PayslipBreakdownScreen(
                              month: currentMonth, // Tab 1 current month
                              year: DateTime.now().year,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Tab 2: Last 6 months
            SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: 6,
                itemBuilder: (context, index) {
                  final monthDate = _getLastSixMonths()[index];
                  final monthName = _months[monthDate.month - 1];
                  final startDate =
                      DateTime(monthDate.year, monthDate.month, 1);
                  final endDate =
                      DateTime(monthDate.year, monthDate.month + 1, 0);

                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(
                        vertical: 5.0, horizontal: 5.0),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                        leading: Icon(
                          Icons.calendar_today,
                          color: Colors.primaries[4],
                          size: 30,
                        ),
                        title: Text(
                          monthName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
                          style: const TextStyle(fontSize: 12.0),
                        ),
                        onTap: () {
                          final monthDate = _getLastSixMonths()[index];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PayslipBreakdownScreen(
                                month: _months[monthDate.month - 1],
                                year: monthDate.year,
                              ),
                            ),
                          );
                        }),
                  );
                },
              ),
            ),

            // Tab 3: Year filter
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      items: _years.map((year) {
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedYear = value;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = _months[index];
                        final startDate = DateTime(_selectedYear, index + 1, 1);
                        final endDate = DateTime(
                            _selectedYear, index + 2, 0); // end of month

                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 5.0),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 0,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                              leading: Icon(
                                Icons.calendar_today,
                                color: Colors.primaries[4],
                                size: 30,
                              ),
                              title: Text(
                                month,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
                                style: const TextStyle(fontSize: 12.0),
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  payslipBreakdownScreenRoute,
                                  arguments: {
                                    'month': _months[index], // tapped month
                                    'year': _selectedYear, // SELECTED YEAR ✅
                                  },
                                );
                              }),
                        );
                      },
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
