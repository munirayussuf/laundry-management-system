import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least six characters';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);
    try {
      await authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Navigation happens automatically through the router redirect once
      // currentUserProvider emits the signed in profile.
    } catch (e) {
      if (mounted) showErrorSnackBar(context, authService.friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text('Welcome Back', style: AppTextStyles.heading1()),
                const SizedBox(height: 6),
                Text('Log In to continue booking laundry services',
                    style: AppTextStyles.bodyMedium(color: AppColors.textMuted)),
                const SizedBox(height: 36),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.bodyLarge(),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTextStyles.bodyLarge(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 12),
                PremiumButton(label: 'Log In', isLoading: _isLoading, onPressed: _submit),
                const SizedBox(height: 24),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text('Do not have an account? ', style: AppTextStyles.bodyMedium(color: AppColors.textMuted)),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.register),
                        child: Text('Create Account',
                            style: AppTextStyles.bodyMedium(color: AppColors.primaryPink)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
