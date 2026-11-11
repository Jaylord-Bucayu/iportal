import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  static final MaterialColor _primaryColor =
  Colors.primaries[4] as MaterialColor;
  static final Color _primaryDark = _primaryColor.shade700;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final workHistoryAsync = ref.watch(workHistoryProvider);

    final email = auth?.email ?? '—';
    final contactNumber = auth?.fullName ?? '—';
    final office = workHistoryAsync.whenOrNull(
      data: (list) => list.isNotEmpty
          ? (list.first['office_name'] as String?) ?? '—'
          : '—',
    ) ??
        '—';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // 🔳 Header
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: _primaryColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primaryColor, _primaryDark],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),

                // 🪪 ID Card — untouched, embedded as-is
                const GovernmentIDCard(),

                const SizedBox(height: 8),

                // ℹ️ Contact info section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.business_rounded,
                          label: "Office",
                          value: office,
                          color: _primaryColor,
                        ),
                        const Divider(height: 1, indent: 56),
                        _InfoTile(
                          icon: Icons.email_rounded,
                          label: "Email",
                          value: email,
                          color: _primaryColor,
                        ),
                        const Divider(height: 1, indent: 56),
                        _InfoTile(
                          icon: Icons.phone_rounded,
                          label: "Contact Number",
                          value: contactNumber,
                          color: _primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🚪 Logout button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Log out"),
                            content: const Text(
                                "Are you sure you want to log out?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ref.read(authProvider.notifier).logout();
                                },
                                child: const Text(
                                  "Log out",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text("Log out"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ==========================================================
/// GovernmentIDCard — unchanged from your original file
/// ==========================================================
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
    ) ??
        'Position';

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