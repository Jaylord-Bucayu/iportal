import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

enum DayPortion { whole, am, pm }

class LeaveDateItem {
  DateTime date;
  DayPortion portion;

  LeaveDateItem({
    required this.date,
    this.portion = DayPortion.whole,
  });
}

class LeaveDateSelector extends StatefulWidget {
  final List<LeaveDateItem> selectedDates;
  final Function(List<LeaveDateItem>) onChanged;
  final String? leaveTypeName;

  const LeaveDateSelector({
    super.key,
    required this.selectedDates,
    required this.onChanged,
    this.leaveTypeName,
  });

  @override
  State<LeaveDateSelector> createState() => _LeaveDateSelectorState();
}

class _LeaveDateSelectorState extends State<LeaveDateSelector> {
  DateTime _focusedDay = DateTime.now();

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  LeaveDateItem? _findItem(DateTime date) {
    try {
      return widget.selectedDates.firstWhere((d) => _isSameDate(d.date, date));
    } catch (_) {
      return null;
    }
  }

  bool _isDateEnabled(DateTime date) {
    final today = DateTime.now();
    final fiveDaysLater = today.add(const Duration(days: 5));

    if (widget.leaveTypeName == null) return false;
    if (widget.leaveTypeName == 'Vacation Leave') {
      return !date.isBefore(fiveDaysLater);
    }
    return true;
  }

  void _toggleDate(DateTime date) {
    if (!_isDateEnabled(date)) return;

    final existing = _findItem(date);

    setState(() {
      if (existing != null) {
        widget.selectedDates.remove(existing);
      } else {
        widget.selectedDates.add(LeaveDateItem(date: date));
      }
      widget.selectedDates.sort((a, b) => a.date.compareTo(b.date));
    });

    widget.onChanged(widget.selectedDates);
  }

  void _removeDate(LeaveDateItem item) {
    setState(() => widget.selectedDates.remove(item));
    widget.onChanged(widget.selectedDates);
  }

  String _formatFullDate(DateTime d) => DateFormat('MMMM d, yyyy').format(d);
  String _formatWeekday(DateTime d) => DateFormat('EEEE').format(d);

  Future<void> _showPortionPicker(LeaveDateItem item) async {
    final portions = DayPortion.values;
    int selectedIndex = portions.indexOf(item.portion);

    final result = await showDialog<DayPortion>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            height: 200,
            child: Column(
              children: [
                const Text(
                  'Select Portion',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: CupertinoPicker(
                    scrollController:
                        FixedExtentScrollController(initialItem: selectedIndex),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      selectedIndex = index;
                    },
                    children: portions
                        .map((p) => Center(child: Text(p.name.toUpperCase())))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 120,
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.primaries[4],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(portions[selectedIndex]);
                      },
                      child: const Text('Select',
                          style: TextStyle(color: Colors.white)),
                  ),
                ),
                )
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() => item.portion = result);
      widget.onChanged(widget.selectedDates);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Calendar
        Card(
          color: Colors.grey.shade100,     
          elevation: 0,
          child: TableCalendar(
            calendarStyle :CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              disabledTextStyle: TextStyle(
                color: Colors.grey.shade400,
              ),
            ),
            headerStyle : const HeaderStyle(
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              formatButtonVisible: false,
              leftChevronIcon: Icon(Icons.chevron_left, size: 28),
              rightChevronIcon: Icon(Icons.chevron_right, size: 28),
            ),
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => _findItem(day) != null,
            enabledDayPredicate: _isDateEnabled,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _toggleDate(selectedDay);
            },
          ),
        ),

        const SizedBox(height: 12),

        /// Selected Dates List with swipe-to-delete
        if (widget.selectedDates.isNotEmpty)
          Column(
            children: widget.selectedDates.map((d) {
              int index = widget.selectedDates.indexOf(d);
              return Column(
                children: [
                  Dismissible(
                    key: ValueKey(d.date),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _removeDate(d),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Weekday + Full date
                          Text(
                            "${_formatWeekday(d.date)}, ${_formatFullDate(d.date)}",
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87),
                          ),
                            const SizedBox(height: 4),
                          /// Portion picker
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _showPortionPicker(d),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    d.portion.name.toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// Full-width divider except last item
                  if (index != widget.selectedDates.length - 1)
                     Divider(
                      color: Colors.grey.shade300,
                      height: 1,
                      thickness: 1,
                    ),
                ],
              );
            }).toList(),
          ),
           Divider(
                      color: Colors.grey.shade300,
                      height: 1,
                      thickness: 1,
                    )
      ],
    );
  }
}