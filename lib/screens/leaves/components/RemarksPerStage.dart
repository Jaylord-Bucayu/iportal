import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shop/constants.dart';

class RemarksPerStage extends StatelessWidget {
  final List<dynamic> remarks;
  final String defaultImageUrl;
  final bool isLoading;

  const RemarksPerStage({
    super.key,
    required this.remarks,
    this.defaultImageUrl = 'https://via.placeholder.com/50',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: List.generate(
          3,
          (i) => _RemarkItem(
            data: const {},
            defaultImageUrl: '',
            isLast: i == 2,
            isLoading: true,
          ),
        ),
      );
    }

    final safeRemarks = remarks.whereType<Map<String, dynamic>>().toList();

    if (safeRemarks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No remarks yet.',
          style: TextStyle(fontSize: 13, color: C.textLow),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(safeRemarks.length, (i) {
        final isLast = i == safeRemarks.length - 1;
        return _RemarkItem(
          data: safeRemarks[i],
          defaultImageUrl: defaultImageUrl,
          isLast: isLast,
        );
      }),
    );
  }
}

class _RemarkItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final String defaultImageUrl;
  final bool isLast;
  final bool isLoading;

  const _RemarkItem({
    required this.data,
    required this.defaultImageUrl,
    required this.isLast,
    this.isLoading = false,
  });

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('MMM d, yyyy · h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  Widget _shimmer({required double width, double height = 12, double radius = 6}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = data['staff_name'] as String? ?? 'Unknown';
    final staffId = data['staff_id'] as int? ?? 000000;
    final remark = data['remarks'] as String? ?? '';
    final imageUrl = 'https://fo2-staff-search.dswd.gov.ph/images/${staffId}.jpg' as String? ?? defaultImageUrl;
    final date = _formatDate(data['created_at'] as String?);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline column ──────────────────
          Column(
            children: [
              // Avatar
              isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade50,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    )
                  : CircleAvatar(
                      radius: 18,
                      backgroundColor: C.primaryLight,
                      backgroundImage: NetworkImage(imageUrl),
                    ),
              // Connector line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: C.textLow.withOpacity(0.2),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // ── Content ──────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + date row
                  Row(
                    children: [
                      Expanded(
                        child: isLoading
                            ? _shimmer(width: 120, height: 13)
                            : Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: C.textHi,
                                  letterSpacing: -0.1,
                                ),
                              ),
                      ),
                      if (isLoading)
                        _shimmer(width: 80, height: 11)
                      else if (date.isNotEmpty)
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 11,
                            color: C.textLow,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Remark bubble
                  if (isLoading)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmer(width: double.infinity, height: 12),
                        const SizedBox(height: 6),
                        _shimmer(width: 160, height: 12),
                      ],
                    )
                  else if (remark.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        remark,
                        style: const TextStyle(
                          fontSize: 12,
                          color: C.textMid,
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}