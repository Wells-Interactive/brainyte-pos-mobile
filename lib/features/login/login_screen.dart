import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/login_strings.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/utils/error_handler.dart';
import '../../routing/app_router.dart';
import '../../widgets/confirm_exit_scope.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository(ApiClient.instance);
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _homeDeliveryEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final result = await ApiClient.instance.get<Map<String, dynamic>>(
        Endpoints.legacySettings,
      );
      if (result.success && result.data != null) {
        final data = result.data!;
        final settings = data['settings'] as Map<String, dynamic>?;
        if (settings != null) {
          final enabled = settings['home_delivery_enabled']?.toString() == '1';
          if (mounted) {
            setState(() => _homeDeliveryEnabled = enabled);
          }
        }
      }
    } catch (e) {
      // Use default false
    }
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _authRepository.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (!result.success || result.data == null) {
      final errorMessage = result.error ?? ErrorHandler.signInFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getFriendlyError(Exception(errorMessage))),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final role = result.data!.role.toLowerCase();
    final route = switch (role) {
      'admin' => AppRouter.admin,
      'owner' => AppRouter.owner,
      'manager' => AppRouter.manager,
      'supervisor' => AppRouter.supervisor,
      'kitchen' => AppRouter.kitchen,
      'bar' => AppRouter.bar,
      'customer' => AppRouter.customerDelivery,
      'rider' => AppRouter.riderDelivery,
      _ => AppRouter.waiter,
    };

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitScope(
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: AppColors.accent,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      LoginStrings.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LoginStrings.appSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              LoginStrings.signIn,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: LoginStrings.emailLabel,
                                hintText: LoginStrings.emailHint,
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Email is required'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submitLogin(),
                              decoration: InputDecoration(
                                labelText: LoginStrings.passwordLabel,
                                hintText: LoginStrings.passwordHint,
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Password is required'
                                      : null,
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              height: 52,
                              child: FilledButton.icon(
                                onPressed: _isSubmitting ? null : _submitLogin,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.login, size: 20),
                                label: Text(
                                  _isSubmitting ? LoginStrings.signingIn : LoginStrings.signInButton,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (_homeDeliveryEnabled) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacementNamed(
                                    AppRouter.customerRegistration,
                                  );
                                },
                                child: const Text(LoginStrings.registerAsCustomer),
                              ),
                            ],
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed(
                                  AppRouter.passwordReset,
                                );
                              },
                              child: const Text(LoginStrings.forgotPassword),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Powered by Brainyte',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
