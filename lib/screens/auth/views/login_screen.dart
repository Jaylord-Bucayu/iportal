import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/providers/auth_provider.dart';

/// Login state provider
final loginStateProvider = StateNotifierProvider<LoginStateNotifier, LoginState>((ref) {
  return LoginStateNotifier();
});

class LoginState {
  final bool isLoading;
  final String? errorMessage;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LoginStateNotifier extends StateNotifier<LoginState> {
  LoginStateNotifier() : super(const LoginState());

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }

  void clearError() {
    // copyWith can't set null (it keeps the old value), so rebuild the state.
    state = LoginState(isLoading: state.isLoading);
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  Future<void> _handleSsoLogin() async {
    final loginNotifier = ref.read(loginStateProvider.notifier);

    loginNotifier.clearError();
    loginNotifier.setLoading(true);

    try {
      final outcome = await ref.read(authProvider.notifier).loginWithSso();

      if (!mounted) return;

      switch (outcome) {
        case SsoOutcome.success:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            entryPointScreenRoute,
                (route) => false,
          );
          break;

        case SsoOutcome.mfaRequired:
        case SsoOutcome.mfaSetupRequired:
        // TODO: push your MFA screen here. The pending token is in
        // ref.read(authProvider.notifier).ssoPendingToken
          loginNotifier.setError(
            'Multi-factor authentication is required for this account. '
                'MFA is not available in the app yet.',
          );
          break;

        case SsoOutcome.cancelled:
        // User closed the browser — nothing to show.
          break;
      }
    } catch (e) {
      if (mounted) {
        loginNotifier.setError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        loginNotifier.setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginStateProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.06),

              // Logo
              Image.asset(
                'assets/images/dswd-iportal-logo.png', // <-- change to your asset path
                width: 160,
                height: 40,
                fit: BoxFit.contain,
              ),

              SizedBox(height: size.height * 0.05),

              // Title
              Text(
                "Sign in to your\nAccount",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  height: 1.15,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                "Use your DSWD iPortal account to continue",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),

              SizedBox(height: size.height * 0.045),

              // Error banner
              if (loginState.errorMessage != null)
                _ErrorBanner(message: loginState.errorMessage!),

              SizedBox(height: size.height * 0.02),

              // SSO button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.primaries[4],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: loginState.isLoading ? 0 : 2,
                  ),
                  onPressed: loginState.isLoading ? null : _handleSsoLogin,
                  child: loginState.isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.7),
                      ),
                    ),
                  )
                      : const Text(
                    "Sign in with SSO",
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.06),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error banner widget
class _ErrorBanner extends StatefulWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  State<_ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<_ErrorBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation.drive(
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 12.0,
        ),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: Colors.red.shade200,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade700,
              size: 20,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                widget.message,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}