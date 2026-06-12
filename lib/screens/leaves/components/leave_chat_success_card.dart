import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop/route/screen_export.dart';

class LeaveSuccessCard extends StatelessWidget {
  final leave;
  final String? referenceNumber;

  const LeaveSuccessCard({
    super.key,
    required this.leave,
    this.referenceNumber,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDates = leave.leaveDates.map((d) {
      final parsed = DateTime.parse(d.date);
      final label = DateFormat('MMMM d, yyyy').format(parsed);
      if (d.type == 'AM_HALF') return '$label (AM)';
      if (d.type == 'PM_HALF') return '$label (PM)';
      return label;
    }).join('\n');

    final totalDays = leave.leaveDates.length;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You filled leave ✅',
            style: TextStyle(
              color: Color(0xFF1A202C),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (referenceNumber != null) ...[
            _PlainRow(label: 'Reference No.', value: referenceNumber!),
            const SizedBox(height: 8),
          ],
          _PlainRow(label: 'Leave Type', value: leave.leaveTypeLabel),
          const SizedBox(height: 8),
          _PlainRow(label: 'Date(s)', value: formattedDates),
          const SizedBox(height: 8),
          _PlainRow(
            label: 'Total Days',
            value: '$totalDays day${totalDays > 1 ? 's' : ''}',
          ),
          if (leave.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PlainRow(label: 'Reason', value: leave.reason),
          ],
          if (leave.attachedFiles.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PlainRow(
              label: 'Attachments',
              value:
                  '${leave.attachedFiles.length} file${leave.attachedFiles.length > 1 ? 's' : ''} attached',
            ),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: leave.id != null
                ? () => Navigator.of(context, rootNavigator: true).pushNamed(
                      leaveActionScreenRoute,
                      arguments: leave.id.toString(),
                    )
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF1FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'View Leave',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1A6BFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainRow extends StatelessWidget {
  final String label;
  final String value;

  const _PlainRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF4A5568),
          height: 1.6,
        ),
        children: [
          TextSpan(
            text: '$label\n',
            style: const TextStyle(color: Color(0xFF8A94A6)),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: Color(0xFF1A202C)),
          ),
        ],
      ),
    );
  }
}
