import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';

// Just for demo
const productDemoImg1 = "https://files01.pna.gov.ph/ograph/2022/02/04/dswd-social-worker.jpg";
const productDemoImg2 = "https://livelihood.dswd.gov.ph/storage/images_cover/201808221534907874.jpg";
const productDemoImg3 = "https://laoagcity.gov.ph/wp-content/uploads/2023/08/361898824_605888345027239_7877592985388665199_n-1024x576.jpg";
const productDemoImg4 = "https://livelihood.dswd.gov.ph/storage/images_cover/201808221534907874.jpg";
const productDemoImg5 = "https://i0.wp.com/palawan-news.com/wp-content/uploads/2024/02/dswd.jpg?fit=640%2C376&ssl=1";
const productDemoImg6 = "https://files01.pna.gov.ph/ograph/2022/12/12/lgzp-slplag.jpg";


// lib/constants.dart
/// Centralized mapping of deduction/benefit codes to their SVG icons.
/// All icons are expected under `assets/logo/`.
class DeductionIcons {
  static const String basePath = 'assets/logo';

  /// Map code -> asset path
  static const Map<String, String> map = {
    'PHIC': '$basePath/phic.png',
    'PAG-IBIG CONT': '$basePath/pagibig.png',
    'PAG-IBIG MP2': '$basePath/pagibigMP2.png',
    'PAG-IBIG MPL': '$basePath/pagibigMPL.png',

    // The following are best-guess filenames — update if your actual files differ.
    'PAG-IBIG CL': '$basePath/pagibigCL.png',        // Calamity Loan
    'PAG-IBIG REL': '$basePath/pagibigREL.png',      // Restructured Loan
    'PAG-IBIG SL': '$basePath/pagibigSL.png',        // Short-term Loan
    'SSS CONT': '$basePath/sss.png',
    'GSIS CONSO LOAN': '$basePath/gsisConsoLoan.png',
    'GSIS REL': '$basePath/gsisREL.png',
    'LBP SL': '$basePath/lbpSL.png',                 // LandBank Salary Loan
    'SWEAP CONT': '$basePath/sweap.jpg',
    'SWEAP LOAN': '$basePath/sweap.jpg',
  };

  /// Returns the asset path for a given code, or a fallback.
  static String assetFor(String code, {String fallback = '$basePath/default.svg'}) {
    return map[code.trim().toUpperCase()] ?? fallback;
  }
}

// End For demo

const grandisExtendedFont = "Grandis Extended";

// On color 80, 60.... those means opacity

const Color primaryColor = Color.fromARGB(255, 12, 77, 162);

const MaterialColor primaryMaterialColor =
    MaterialColor(0xFF0C4DA2, <int, Color>{
  50: Color(0xFFE2EAF4), // Lightest shade
  100: Color(0xFFB6CBE6),
  200: Color(0xFF85A9D7),
  300: Color(0xFF5487C8),
  400: Color(0xFF2F6EBB),
  500: Color(0xFF0C4DA2), // Primary color
  600: Color(0xFF0A4694),
  700: Color(0xFF083D83),
  800: Color(0xFF063572),
  900: Color(0xFF032555), // Darkest shade
});

const Color blackColor = Color(0xFF16161E);
const Color blackColor80 = Color(0xFF45454B);
const Color blackColor60 = Color(0xFF737378);
const Color blackColor40 = Color(0xFFA2A2A5);
const Color blackColor20 = Color(0xFFD0D0D2);
const Color blackColor10 = Color(0xFFE8E8E9);
const Color blackColor5 = Color(0xFFF3F3F4);

const Color whiteColor = Colors.white;
const Color whileColor80 = Color(0xFFCCCCCC);
const Color whileColor60 = Color(0xFF999999);
const Color whileColor40 = Color(0xFF666666);
const Color whileColor20 = Color(0xFF333333);
const Color whileColor10 = Color(0xFF191919);
const Color whileColor5 = Color(0xFF0D0D0D);

const Color greyColor = Color(0xFFB8B5C3);
const Color lightGreyColor = Color(0xFFF8F8F9);
const Color darkGreyColor = Color(0xFF1C1C25);
// const Color greyColor80 = Color(0xFFC6C4CF);
// const Color greyColor60 = Color(0xFFD4D3DB);
// const Color greyColor40 = Color(0xFFE3E1E7);
// const Color greyColor20 = Color(0xFFF1F0F3);
// const Color greyColor10 = Color(0xFFF8F8F9);
// const Color greyColor5 = Color(0xFFFBFBFC);

const Color purpleColor = Color(0xFF7B61FF);
const Color successColor = Color(0xFF2ED573);
const Color warningColor = Color(0xFFFFBE21);
const Color errorColor = Color(0xFFEA5B5B);

const double defaultPadding = 16.0;
const double defaultBorderRadious = 12.0;
const Duration defaultDuration = Duration(milliseconds: 300);

final passwordValidator = MultiValidator([
  RequiredValidator(errorText: 'Password is required'),
  MinLengthValidator(8, errorText: 'password must be at least 8 digits long'),
  PatternValidator(r'(?=.*?[#?!@$%^&*-])',
      errorText: 'passwords must have at least one special character')
]);

final emaildValidator = MultiValidator([
  RequiredValidator(errorText: 'Email is required'),
  EmailValidator(errorText: "Enter a valid email address"),
]);

const pasNotMatchErrorText = "passwords do not match";


// ════════════════════════════════════════════════════
// DESIGN TOKENS
// ════════════════════════════════════════════════════

 abstract class C {
  static const primary      = Color(0xFF1877F2);
  static const primaryLight = Color(0xFFE7F0FD);
  static const bg           = Color(0xFFF0F2F5);
  static const surface      = Color(0xFFFFFFFF);
  static const divider      = Color(0xFFE4E6EB);
  static const textHi       = Color(0xFF050505);
  static const textMid      = Color(0xFF65676B);
  static const textLow      = Color(0xFF8A8D91);

  static const approvedFg  = Color(0xFF1A7F4B);
  static const approvedBg  = Color(0xFFE3F5EC);
  static const approvedBar = Color(0xFF23C16B);

  static const pendingFg   = Color(0xFFB45309);
  static const pendingBg   = Color(0xFFFFF3DC);
  static const pendingBar  = Color(0xFFF59E0B);

  static const rejectedFg  = Color(0xFFD93025);
  static const rejectedBg  = Color(0xFFFFEAE8);
  static const rejectedBar = Color(0xFFEF4444);

  static const neutralFg   = Color(0xFF65676B);
  static const neutralBg   = Color(0xFFF0F2F5);
  static const timelinePend = Color(0xFFCCD0D5);
}
