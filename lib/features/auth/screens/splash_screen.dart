import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void initState() {
    super.initState();
    _decideNextRoute();
  }

  Future<void> _decideNextRoute() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null) return; // router redirect sends the user to their home

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    if (!mounted) return;
    context.go(seenOnboarding ? AppRoutes.login : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: FadeTransition(
            opacity: _controller,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    gradient: AppColors.pinkGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(color: AppColors.pinkGlow, blurRadius: 40, spreadRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.local_laundry_service_rounded,
                      size: 48, color: AppColors.white),
                ),
                const SizedBox(height: 24),
                Text('Laundry Service', style: AppTextStyles.heading1()),
                const SizedBox(height: 4),
                Text('Formal and Mama Fua Providers, Together',
                    style: AppTextStyles.bodyMedium(color: AppColors.primaryPink)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
