import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/screens/reservs/reservs_in_app_screen.dart';
import 'package:shop/screens/verms/verms_in_app_screen.dart';
import '../../../../constants.dart';

/// Model representing a category button.
class CategoryModel {
  final String name; // Category name.
  final String? svgSrc; // Path to the SVG asset.
  final String? route; // Route to navigate to when clicked.

  CategoryModel({
    required this.name,
    this.svgSrc,
    this.route,
  });
}

// List of demo categories.
List<CategoryModel> demoCategories = [
  // CategoryModel(name: "In/Out", svgSrc: "assets/icons/Fingerprint.svg",route:"time_in_out"),
  CategoryModel(name: "Leaves", svgSrc: "assets/icons/Calender.svg",route:"leaves"),
  // CategoryModel(name: "Docs", svgSrc: "assets/icons/Message.svg", route:"my_documents"),
  // CategoryModel(name: "Pass-Slip", svgSrc: "assets/icons/Delivery.svg",route: 'pass_slip'),
  // CategoryModel(name: "Payslip", svgSrc: "assets/icons/Order.svg",route: "payslip"),
  // CategoryModel(name: "Loan", svgSrc: "assets/icons/Wallet.svg",route: "loan_home"),
  // CategoryModel(name: "Reservs", svgSrc: "assets/icons/Return.svg",route: "pin"),
  // CategoryModel(name: "Verms", svgSrc: "assets/icons/Delivery.svg"),
];

/// Categories widget: Displays a grid of circular category buttons.
class Categories extends StatelessWidget {
  const Categories({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: defaultPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // Four items per row.
          crossAxisSpacing: 12.2, // Spacing between columns.
          mainAxisSpacing: defaultPadding, // Spacing between rows.
          childAspectRatio: 1, // Adjust aspect ratio to make items square.
        ),
        itemCount: demoCategories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0), // Left & Right margin.
            child: CategoryButton(
              category: demoCategories[index],
              press: () async {
            final category = demoCategories[index];

            if (category.name == "Reservs") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReservsWebViewScreen()),
              );
            }
            if (category.name == "Verms") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VermsWebViewScreen()),
              );
            }  else if (category.route != null) {
              Navigator.pushNamed(context, category.route!);
            }
          },
            ),
          );
        },
      ),
    );
  }
}

/// A circular button widget representing a single category.
class CategoryButton extends StatelessWidget {
  final CategoryModel category; // Category model containing data.
  final VoidCallback press; // Action to perform on button press.

  const CategoryButton({
    super.key,
    required this.category,
    required this.press,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(50),
            ),
            child: Center(
              child: SvgPicture.asset(
                category.svgSrc ?? '',
                height: 30,
                width: 30,
                colorFilter: const ColorFilter.mode(
                  primaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding / 2),
          Text(
            category.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
