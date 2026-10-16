import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);
    try {
      await authService.sendPasswordResetEmail(_emailController.text);
      setState(() => _sent = true);
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
      appBar: const PinkAppBar(title: 'Reset Password', subtitle: 'We will email you a reset link'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent
              ? EmptyStateView(
                  icon: Icons.mark_email_read_rounded,
                  title: 'Check Your Email',
                  message: 'We sent a password reset link to ${_emailController.text.trim()}',
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Forgot Your Password?', style: AppTextStyles.heading2()),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the email address linked to your account and we will send you a reset link.',
                        style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          return regex.hasMatch(v.trim()) ? null : 'Enter a valid email address';
                        },
                      ),
                      const SizedBox(height: 24),
                      PremiumButton(label: 'Send Reset Link', isLoading: _isLoading, onPressed: _submit),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
