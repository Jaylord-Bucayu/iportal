import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/providers/auth_provider.dart';

class EntryPoint extends ConsumerStatefulWidget {
  const EntryPoint({super.key});

  @override
  ConsumerState<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends ConsumerState<EntryPoint> {
  final List _pages = [
    const HomeScreen(),
     DirectoryHomeScreen(),
    // DiscoverScreen(),
    // const BookmarkScreen(),
    // EmptyCartScreen(), // if Cart is empty
    // const CartScreen(),
    const ProfileScreen(),
  ];
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider); // ✅ read from existing authProvider
    final staffId = auth?.staffId?.toString() ?? '';
    final fullName = auth?.fullName ?? 'User';
    final imageUrl = 'https://fo2-staff-search.dswd.gov.ph/images/$staffId.jpg';

    SvgPicture svgIcon(String src, {Color? color}) {
      return SvgPicture.asset(
        src,
        height: 24,
        // colorFilter: ColorFilter.mode(
        //     color ??
        //         Theme.of(context).iconTheme.color!.withOpacity(
        //             Theme.of(context).brightness == Brightness.dark ? 0.3 : 1),
        //     BlendMode.srcIn),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const SizedBox(),
        leadingWidth: 0,
        centerTitle: false,
        toolbarHeight: 80, // increase height for subtitle
        title: Row(
          children: [
            // Staff photo from network using staff_id
            ClipOval(
              child: Image.network(
                imageUrl,
                height: 45,
                width: 45,
                fit: BoxFit.cover,
                // Show placeholder while loading
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 45,
                    width: 45,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
                // Fallback if image fails to load
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 26,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Greeting and subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hi, $fullName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Welcome to DSWD FO2 IPORTAL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        // actions: [
        //   IconButton(
        //     onPressed: () {
        //       Navigator.pushNamed(context, notificationsScreenRoute);
        //     },
        //     icon: SvgPicture.asset(
        //       "assets/icons/Notification.svg",
        //       height: 24,
        //       colorFilter: ColorFilter.mode(
        //           Theme.of(context).textTheme.bodyLarge!.color!,
        //           BlendMode.srcIn),
        //     ),
        //   ),
        // ],
      ),
      //body: _pages[_currentIndex],
      body: PageTransitionSwitcher(
        duration: defaultDuration,
        transitionBuilder: (child, animation, secondAnimation) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondAnimation,
            child: child,
          );
        },
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        // padding: const EdgeInsets.only(top: defaultPadding),
        // color: Theme.of(context).brightness == Brightness.light
        //     ? Colors.white
        //     : const Color(0xFF101015),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index != _currentIndex) {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          // selectedLabelStyle: TextStyle(color: primaryColor),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedItemColor: primaryColor,
          // unselectedItemColor: Colors.transparent,
          items: [
            BottomNavigationBarItem(
              icon: svgIcon("assets/icons/Home.svg"),
              activeIcon:
                  svgIcon("assets/icons/Home.svg", color: primaryColor),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: svgIcon("assets/icons/Location.svg"),
              activeIcon: svgIcon("assets/icons/Location.svg", color: primaryColor),
              label: "Directories",
            ),

            // BottomNavigationBarItem(
            //   backgroundColor: primaryColor,
            //   icon: svgIcon("assets/icons/News.svg"),
            //   activeIcon:
            //       svgIcon("assets/icons/News.svg", color: primaryColor),
            //   label: "News",
            // ),
            // BottomNavigationBarItem(
            //   icon: svgIcon("assets/icons/Activity.svg"),
            //   activeIcon: svgIcon("assets/icons/Activity.svg", color: primaryColor),
            //   label: "Activity",
            // ),
            BottomNavigationBarItem(
              icon: svgIcon("assets/icons/User.svg"),
              activeIcon:
                  svgIcon("assets/icons/User.svg", color: primaryColor),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}