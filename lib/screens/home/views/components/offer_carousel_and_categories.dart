import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/components/dswd_hero_banner.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/home/views/components/categories.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/screens/news/news_wp.dart';

class OffersCarouselAndCategories extends ConsumerWidget {
  const OffersCarouselAndCategories({super.key});

  static const double cardOverlap = 40; // how far the card hangs below the banner

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 22) return 'Good Evening';
    return 'Hello';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider);

    final greeting = _getGreeting();
    final firstName = getFirstName(authUser?.fullName);
    final staffId = authUser?.staffId ?? 'Guest';

    // Part of the card that sits inside the banner
    const coveredByCard = categoriesCardHeight - cardOverlap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            // Full-height banner (extends under the status bar).
            // Bottom padding leaves room for the card to hang below it.
            Padding(
              padding: const EdgeInsets.only(bottom: cardOverlap),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  bottom: coveredByCard + 8,
                ),
                child: DswdHeroBanner(
                  userName: firstName,
                  greeting: greeting,
                  imageUrl:
                  'https://fo2-staff-search.dswd.gov.ph/images/$staffId.jpg',
                  title: '',
                  subtitle: '',
                ),
              ),
            ),

            // Floating categories card, pinned to the bottom of the stack
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Categories(),
            ),
          ],
        ),

        const SizedBox(height: defaultPadding),

        const NewsWP(),
      ],
    );
  }
}