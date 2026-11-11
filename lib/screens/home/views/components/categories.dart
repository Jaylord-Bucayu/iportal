import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/screens/reservs/reservs_in_app_screen.dart';
import 'package:shop/screens/verms/verms_in_app_screen.dart';
import 'package:shop/providers/auth_provider.dart';
import '../../../../constants.dart';

/// Height of the floating card. Used by the parent to calculate overlap.
const double categoriesCardHeight = 104;

/// Model representing a single shortcut, e.g. "Leaves", "Payslip".
class CategoryModel {
  final String name; // Label under the icon.
  final String logoUrl; // Logo image URL shown inside the circle.
  final Color color; // Circle background color.
  final Color borderColor; // Circle border color.
  final String? route; // Route to navigate to when tapped.

  /// Which appointment statuses can see this category.
  final List<String> forAppointmentStatus;

  const CategoryModel({
    required this.name,
    required this.logoUrl,
    required this.forAppointmentStatus,
    this.color = Colors.white,
    this.borderColor = const Color(0xFFE5E7EB),
    this.route,
  });
}

const _allStatuses = [
  "CONTRACT OF SERVICE - NON-KALAHI",
  "CONTRACT OF SERVICE - KALAHI",
  "CONTRACT OF SERVICE - NON-KALAHI-2",
  "PERMANENT",
  "CONTRACTUAL",
];

const _regular = [
  "PERMANENT",
  "CONTRACTUAL",
];


// TODO: confirm the correct forAppointmentStatus list per category —
// currently defaulted to "visible to everyone".
const List<CategoryModel> demoCategories = [
  CategoryModel(
    name: "Leaves",
    logoUrl: "https://fo2-staff-search.dswd.gov.ph/uploads/logo/leave.png",
    route: "leaves",
    forAppointmentStatus: _regular,
  ),
  CategoryModel(
    name: "Payslip",
    logoUrl: "https://fo2-staff-search.dswd.gov.ph/uploads/logo/payslip.png",
    route: "payslip",
    forAppointmentStatus: _allStatuses,
  ),
  // CategoryModel(
  //   name: "eClearance",
  //   logoUrl: "https://fo2-staff-search.dswd.gov.ph/uploads/logo/eclearance.png",
  //   route: "my_documents",
  //   forAppointmentStatus: _allStatuses,
  // ),
  CategoryModel(
    name: "eDLVS",
    logoUrl: "https://fo2-staff-search.dswd.gov.ph/uploads/logo/edlvs.png",
    route: "uber",
    forAppointmentStatus: _allStatuses,
  ),
];

/// Portrait promo image shown when eClearance is tapped.
// TODO: replace with the real "coming soon" image URL.
const String eClearanceComingSoonUrl =
    "https://fo2-staff-search.dswd.gov.ph/uploads/logo/eclearance_coming_soon.png";

/// Shows a portrait, image-only "coming soon" modal.
/// Tap outside the image or the close button to dismiss.
void showComingSoonModal(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (dialogContext) {
      final maxHeight = MediaQuery.of(dialogContext).size.height * 0.75;

      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Container(
                    height: maxHeight * 0.6,
                    color: Colors.white,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorBuilder: (_, __, ___) => Container(
                    height: maxHeight * 0.6,
                    color: Colors.white,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 40,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(dialogContext),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Floating white card holding the category shortcuts,
/// filtered by the current user's appointment_status.
class Categories extends ConsumerWidget {
  const Categories({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workHistoryAsync = ref.watch(workHistoryProvider);

    final appointmentStatus = workHistoryAsync.whenOrNull(
      data: (list) => list.isNotEmpty
          ? (list.first['appointment_status'] as String?) ?? 'Permanent'
          : 'Permanent',
    ) ??
        'Permanent';

    final visibleCategories = demoCategories
        .where((c) => c.forAppointmentStatus.contains(appointmentStatus))
        .toList();

    return Container(
      height: categoriesCardHeight,
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: visibleCategories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppShortcutTile(
              category: category,
              press: () {
                if (category.name == "eClearance") {
                  showComingSoonModal(context, eClearanceComingSoonUrl);
                } else if (category.name == "eDLVS") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReservsWebViewScreen(),
                    ),
                  );
                } else if (category.name == "Verms") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VermsWebViewScreen(),
                    ),
                  );
                } else if (category.route != null) {
                  Navigator.pushNamed(context, category.route!);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A circular logo (white with a border) and its label underneath.
class AppShortcutTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback press;

  const AppShortcutTile({
    super.key,
    required this.category,
    required this.press,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
                border: Border.all(color: category.borderColor, width: 0.5),
              ),
              padding: const EdgeInsets.all(12),
              child: Image.network(
                category.logoUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported_outlined,
                  size: 22,
                  color: Colors.black38,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}