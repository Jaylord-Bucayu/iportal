import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/keycloak_auth.dart';
import 'package:shop/providers/auth_provider.dart';
import 'components/login_form.dart';

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
    state = state.copyWith(errorMessage: null);
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _email;
  String? _password;

  void _handleLogin() async {
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      ref.read(loginStateProvider.notifier).setError('Please fill in all fields');
      return;
    }

    form.save();

    if (_email == null || _password == null) {
      ref.read(loginStateProvider.notifier).setError('Email and password are required');
      return;
    }

    ref.read(loginStateProvider.notifier).clearError();
    ref.read(loginStateProvider.notifier).setLoading(true);

    try {
      final tokenResponse = await authenticateWithKeycloak(_email!, _password!);

      if (!mounted) return;

      if (tokenResponse == null) {
        throw Exception('Login failed. Please check your credentials.');
      }

      final accessToken = tokenResponse['access_token'] as String? ?? '';
      final refreshToken = tokenResponse['refresh_token'] as String? ?? '';

      if (accessToken == null) {
        throw Exception('No access token received from authentication');
      }

      final userInfo = await fetchUserInfo(accessToken);

      if (!mounted) return;

      final email = userInfo?['email'] as String? ?? _email ?? '';
      final fullName = userInfo?['name'] as String? ?? 'User';

      ref.read(authProvider.notifier).login(
        accessToken: accessToken,
        refreshToken: refreshToken,
        email: email,
        fullName: fullName,
        staffId: int.parse(userInfo?['staffId']),
      );

      if (!mounted) return;

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
    } on Exception catch (e) {
      if (mounted) {
        ref.read(loginStateProvider.notifier).setError(
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        ref.read(loginStateProvider.notifier).setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginStateProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.06),

              // Logo and title
              Column(
                children: [
                  // Logo
                 Center(
                    child: Image.asset(
                      'assets/images/dswd-pilipinas.png', // <-- change to your asset path
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
               
                                  

                  // Title
                  Text(
                    "Welcome to IPortal",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    "Sign up or login below to manage your\nproject, task, and productivity",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      height: 1.5,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.05),

              // Error banner
              if (loginState.errorMessage != null)
                _ErrorBanner(message: loginState.errorMessage!),

              // Form
              LogInForm(
                formKey: _formKey,
                onSavedEmail: (email) => _email = email,
                onSavedPassword: (password) => _password = password,
              ),

              const SizedBox(height: 16),

              // Forgot password link
              // Align(
              //   alignment: Alignment.centerLeft,
              //   child: GestureDetector(
              //     onTap: () {
              //       // TODO: Implement forgot password
              //     },
              //     child: Text(
              //       "Forgot Password?",
              //       style: TextStyle(
              //         color: Colors.grey.shade600,
              //         fontSize: 13,
              //         fontWeight: FontWeight.w500,
              //       ),
              //     ),
              //   ),
              // ),

              SizedBox(height: size.height * 0.04),

              // Login button
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
                  onPressed: loginState.isLoading ? null : _handleLogin,
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
                          "Login",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              SizedBox(height: size.height * 0.08),

              // Terms and privacy
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'By signing up, you agree to our ',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: 'Terms of service',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(
                      text: ' and ',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    TextSpan(
                      text: 'Privacy policy',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
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