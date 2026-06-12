import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/auth_provider.dart';

class GovernmentIDCard extends ConsumerWidget {
  const GovernmentIDCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final workHistoryAsync = ref.watch(workHistoryProvider);

    final staffId = auth?.staffId?.toString() ?? '';
    final fullName = auth?.fullName ?? 'No Name';
    final photoUrl = 'https://fo2-staff-search.dswd.gov.ph/images/$staffId.jpg';

    // Get position_name from first active work history record
   final position = workHistoryAsync.whenOrNull(
      data: (list) => list.isNotEmpty 
          ? (list.first['position_name'] as String?) ?? 'Position' 
          : 'Position',
    ) ?? 'Position';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 180,
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Header image
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/dswd-pilipinas.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Photo from network using staff_id
              ClipRect(
                child: Image.network(
                  photoUrl,
                  width: 100,
                  height: 130,
                  fit: BoxFit.cover,
                  // Show placeholder while loading
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 100,
                      height: 130,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  // Fallback if image fails to load
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 130,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.person, size: 50),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Name
              Text(
                fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 1),

              // Position from work history
              workHistoryAsync.when(
                data: (_) => Text(
                  position,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                loading: () => const SizedBox(
                  width: 80,
                  height: 12,
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => const Text(
                  'Position',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 16),

              // Signature — hidden for now
              // Column(
              //   children: [
              //     Container(
              //       width: 100,
              //       height: 40,
              //       decoration: BoxDecoration(
              //         border: const Border(
              //           bottom: BorderSide(color: Colors.black, width: 2),
              //         ),
              //         image: (signatureUrl != null && signatureUrl!.isNotEmpty)
              //             ? DecorationImage(
              //                 image: NetworkImage(signatureUrl!),
              //                 fit: BoxFit.contain,
              //               )
              //             : null,
              //       ),
              //     ),
              //   ],
              // ),

              const SizedBox(height: 16),

              // ID Number
              Text(
                "ID NO: $staffId",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.primaries[4],
                ),
              ),

              const Spacer(), // push footer to bottom

              // Footer: red/blue split with bottom border radius
              Row(
                children: [
                  Expanded(
                    flex: 1, // 1/4 red
                    child: Container(
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3, // 3/4 blue
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.primaries[4],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}