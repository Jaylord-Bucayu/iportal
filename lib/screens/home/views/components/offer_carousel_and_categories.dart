import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/screens/home/views/components/home_banner.dart';
import 'package:shop/screens/home/views/components/categories.dart';
import 'package:shop/providers/auth_provider.dart';

class OffersCarouselAndCategories extends ConsumerWidget {
  const OffersCarouselAndCategories({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'Good Evening';
    } else {
      return 'Hello';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider);

    final greeting = _getGreeting();
    final userName = authUser?.fullName ?? 'Guest';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeBanner(
          name: greeting,
          email: userName,
          imageUrl: 'assets/logo/bago-p.png',
        ),
        const Categories(),
      ],
    );
  }
}
