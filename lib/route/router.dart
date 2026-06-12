import 'package:flutter/material.dart';
import 'package:shop/entry_point.dart';
import 'package:shop/screens/directory/views/directory_screen.dart';
import 'package:shop/screens/leaves/views/approval_leave_confirmation_screen.dart';
import 'package:shop/screens/leaves/views/approval_leave_screen.dart';
import 'package:shop/screens/leaves/views/for_leave_approval_screen.dart';
import 'package:shop/screens/leaves/views/leave_action_screen.dart' as action;
import 'package:shop/screens/leaves/views/leave_details_screen.dart' as details;
import 'package:shop/screens/leaves/views/leave_type_details_screen.dart';
import 'package:shop/screens/leaves/views/view_all_leaves_ledger.dart';
import 'package:shop/screens/leaves/views/view_all_leaves_screen.dart';
import 'package:shop/screens/pass-slip/views/apply_pass_slip_screen.dart';
import 'package:shop/screens/pass-slip/views/qr_code_approval_info_screen.dart';
import 'package:shop/screens/payslip/views/payslip_breakdown_screen.dart';
import 'package:shop/screens/pass-slip/views/pass_slip_screen.dart';

import 'screen_export.dart';

// Yuo will get 50+ screens and more once you have the full template
// 🔗 Full template: https://theflutterway.gumroad.com/l/fluttershop

// NotificationPermissionScreen()
// PreferredLanguageScreen()
// SelectLanguageScreen()
// SignUpVerificationScreen()
// ProfileSetupScreen()
// VerificationMethodScreen()
// OtpScreen()
// SetNewPasswordScreen()
// DoneResetPasswordScreen()
// TermsOfServicesScreen()
// SetupFingerprintScreen()
// SetupFingerprintScreen()
// SetupFingerprintScreen()
// SetupFingerprintScreen()
// SetupFaceIdScreen()
// OnSaleScreen()
// BannerLStyle2()
// BannerLStyle3()
// BannerLStyle4()
// SearchScreen()
// SearchHistoryScreen()
// NotificationsScreen()
// EnableNotificationScreen()
// NoNotificationScreen()
// NotificationOptionsScreen()
// ProductInfoScreen()
// ShippingMethodsScreen()
// ProductReviewsScreen()
// SizeGuideScreen()
// BrandScreen()
// CartScreen()
// EmptyCartScreen()
// PaymentMethodScreen()
// ThanksForOrderScreen()
// CurrentPasswordScreen()
// EditUserInfoScreen()
// OrdersScreen()
// OrderProcessingScreen()
// OrderDetailsScreen()
// CancleOrderScreen()
// DelivereOrdersdScreen()
// AddressesScreen()
// NoAddressScreen()
// AddNewAddressScreen()
// ServerErrorScreen()
// NoInternetScreen()
// ChatScreen()
// DiscoverWithImageScreen()
// SubDiscoverScreen()
// AddNewCardScreen()
// EmptyPaymentScreen()
// GetHelpScreen()

// ℹ️ All the comments screen are included in the full template
// 🔗 Full template: https://theflutterway.gumroad.com/l/fluttershop

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case onbordingScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      );
    // case preferredLanuageScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const PreferredLanguageScreen(),
    //   );
    case logInScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      );
    case signUpScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
      );
    case pinScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const PinScreen(),
      );
    // case profileSetupScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const ProfileSetupScreen(),
    //   );
    case passwordRecoveryScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const PasswordRecoveryScreen(),
      );
    // case verificationMethodScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const VerificationMethodScreen(),
    //   );
    // case otpScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const OtpScreen(),
    //   );
    // case newPasswordScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const SetNewPasswordScreen(),
    //   );
    // case doneResetPasswordScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const DoneResetPasswordScreen(),
    //   );
    // case termsOfServicesScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const TermsOfServicesScreen(),
    //   );
    // case noInternetScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const NoInternetScreen(),
    //   );
    // case serverErrorScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const ServerErrorScreen(),
    //   );
    // case signUpVerificationScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const SignUpVerificationScreen(),
    //   );
    // case setupFingerprintScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const SetupFingerprintScreen(),
    //   );
    // case setupFaceIdScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const SetupFaceIdScreen(),
    //   );
    case productDetailsScreenRoute:
      return MaterialPageRoute(
        builder: (context) {
          bool isProductAvailable = settings.arguments as bool? ?? true;
          return ProductDetailsScreen(isProductAvailable: isProductAvailable);
        },
      );
    case productReviewsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ProductReviewsScreen(),
      );
    // case addReviewsScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const AddReviewScreen(),
    //   );
    case homeScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      );
    // case brandScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const BrandScreen(),
    //   );
    // case discoverWithImageScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const DiscoverWithImageScreen(),
    //   );
    // case subDiscoverScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const SubDiscoverScreen(),
    //   );
    case discoverScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const DiscoverScreen(),
      );
    case onSaleScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const OnSaleScreen(),
      );
    case kidsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const KidsScreen(),
      );
    case searchScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      );
    // case searchHistoryScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const SearchHistoryScreen(),
    //   );
    case bookmarkScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const BookmarkScreen(),
      );
    case entryPointScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const EntryPoint(),
      );
    case profileScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      );
    // case getHelpScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const GetHelpScreen(),
    //   );
    // case chatScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const ChatScreen(),
    //   );
    case userInfoScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const UserInfoScreen(),
      );
    // case currentPasswordScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const CurrentPasswordScreen(),
    //   );
    // case editUserInfoScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const EditUserInfoScreen(),
    //   );
    case notificationsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      );
    case noNotificationScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NoNotificationScreen(),
      );
    case enableNotificationScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const EnableNotificationScreen(),
      );
    case notificationOptionsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NotificationOptionsScreen(),
      );
    // case selectLanguageScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const SelectLanguageScreen(),
    //   );
    // case noAddressScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const NoAddressScreen(),
    //   );
    case addressesScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const AddressesScreen(),
      );
    // case addNewAddressesScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const AddNewAddressScreen(),
    //   );
    case ordersScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const OrdersScreen(),
      );
    // case orderProcessingScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const OrderProcessingScreen(),
    //   );
    // case orderDetailsScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const OrderDetailsScreen(),
    //   );
    // case cancleOrderScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const CancleOrderScreen(),
    //   );
    // case deliveredOrdersScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const DelivereOrdersdScreen(),
    //   );
    // case cancledOrdersScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const CancledOrdersScreen(),
    //   );
    case preferencesScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const PreferencesScreen(),
      );
    // case emptyPaymentScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const EmptyPaymentScreen(),
    //   );
    case emptyWalletScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const EmptyWalletScreen(),
      );
    case walletScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const WalletScreen(),
      );
    case cartScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const CartScreen(),
      );
    // case paymentMethodScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const PaymentMethodScreen(),
    //   );
    // case addNewCardScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const AddNewCardScreen(),
    //   );
    // case thanksForOrderScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const ThanksForOrderScreen(),
    //   );
    case directoryScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const DirectoryScreen(),
      );

    case directoryDetailsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => DirectoryDetailsScreen(),
      );

    case docsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const DocsScreen(),
      );

    case myDocumentsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const MyDocumentsScreen(),
      );

    case leavesScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const LeavesScreen(),
      );

      case leaveRequestsScreenRoute:
      final staffId = settings.arguments as int;
      return MaterialPageRoute(
        builder: (context) => LeaveRequestsScreen(staffId: staffId),
      );

   case leaveDetailsScreenRoute:
  {
    final leaveId = settings.arguments as String;
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          details.LeaveDetailScreen(leaveId: leaveId),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
    // case leavePDFScreenRoute:
    // final assetPath = settings.arguments as String;
    // return MaterialPageRoute(
    //   builder: (_) => PdfAssetViewer(assetPath: assetPath),
    // );

case leaveActionScreenRoute:
  {
    final args = settings.arguments as String;
    return MaterialPageRoute(
      builder: (_) => LeaveActionScreen(leaveId: args),
    );
  }

   case approvalleaveConfirmationScreenRoute:
    // Make sure you have the leaveId to pass
    final leaveId = settings.arguments as String; // or get it from your logic

    return MaterialPageRoute(
      builder: (_) => LeaveApprovalConfimationScreen(leaveId: leaveId),
    );  

    case viewLeaveLedgerScreenRoute:
     final staffId = settings.arguments as int; // or get it from your logic

      return MaterialPageRoute(
        builder: (_) => LeaveLedgerScreen(staffId: staffId),
      );

    case leaveApprovalLeavecreenRoute:
      return MaterialPageRoute(
        builder: (_) => const LeaveApprovalScreen(),
      );


  //  case leaveChatScreenRoute:
  //     return MaterialPageRoute(
  //       builder: (_) => const LeaveAssistantApp(),
  //     );

   case leaveListForApprovalLeavecreenRoute:
      final args = settings.arguments as Map<String, dynamic>?;
      final status = args?['status'] ?? 'for_supervisor_review';
      final authorityType = args?['authorityType'] ?? 'supervisor';
      final authorityId = args?['authorityId'] is int
          ? args!['authorityId'] as int
          : int.tryParse(args?['authorityId']?.toString() ?? '') ?? 0;
      return MaterialPageRoute(
        builder: (_) => ForLeaveApprovalScreen(
          status: status,
          authorityType: authorityType,
          authorityId: authorityId,
        ),
      );

   case leaveTypeDetailscreenRoute:
  final args = settings.arguments as Map<String, dynamic>?;

  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => LeaveTypeDetails(
      title: args?['title'] ?? 'Leave Type', // fallback if null
      imagePath: args?['imagePath'] ?? 'assets/images/default.jpg',
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Slide from bottom
      const begin = Offset(0.0, 1.0); // start off-screen at the bottom
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      final tween = Tween(begin: begin, end: end)
          .chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );

    case applyLeaveScreenRoute:
     final staffId = settings.arguments as int; // or get it from your logic

      return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ApplyLeaveScreen(staffId: staffId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide from right transition
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400), // adjust speed
      );

    case passSlipScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const PassSlipScreen(),
      );

    case viewPassSlipScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ViewPassSlipScreen(),
      );

    case applyPassSlipScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ApplyPassSlipScreen(),
      );

    case qrApprovalInfoScreenRoute:
      final args =
          settings.arguments as Map<String, dynamic>; // ✅ Map instead of String
      return MaterialPageRoute(
        builder: (context) => QrApprovalInfoScreen(scannedData: args),
      );

    case timeInOutScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const TimeInOutScreen(),
      );

    case timeInOutHistoryScreenRoute:
      return MaterialPageRoute(
        builder: (context) => TransactionHistoryScreen(),
      );

    case loanScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const LoanScreen(),
      );

    case loanHomeScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const LoanHomeScreen(),
      );

    case payslipScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const PayslipScreen(),
      );

    case payslipBreakdownScreenRoute:
      {
        // Ensure arguments exist and are a Map
        final args = settings.arguments;
        if (args is Map<String, dynamic> &&
            args.containsKey('month') &&
            args.containsKey('year')) {
          final month = args['month'] as String;
          final year = args['year'] as int;

          return MaterialPageRoute(
            builder: (context) => PayslipBreakdownScreen(
              month: month,
              year: year,
            ),
          );
        } else {
          // Arguments missing → maybe navigate back or throw error
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: Text(
                  'Error: Month and Year not provided for PayslipBreakdownScreen',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }
      }

    case notificationsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      );

    case notificationsDetailsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NotificationsDetailsScreen(
          body: '',
          title: '',
        ),
      );

    default:
      return MaterialPageRoute(
        // Make a screen for undefine
        builder: (context) => const PayslipScreen(),
      );
  }
}
