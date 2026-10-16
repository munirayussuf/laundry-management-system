import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class _Slide {
  final IconData icon;
  final String title;
  final String description;
  const _Slide(this.icon, this.title, this.description);
}

const _slides = [
  _Slide(
    Icons.explore_rounded,
    'Find Trusted Laundry Providers',
    'Discover formal laundry businesses and Mama Fua / Jua Kali operators near you, all in one place.',
  ),
  _Slide(
    Icons.local_shipping_rounded,
    'Book Pickup And Delivery',
    'Schedule a pickup, choose your washing and ironing method, and track your order in real time.',
  ),
  _Slide(
    Icons.payments_rounded,
    'Pay Your Way',
    'Pay with mobile money or choose cash on delivery, whichever suits you best.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.pinkGradient,
                            boxShadow: const [
                              BoxShadow(color: AppColors.pinkGlow, blurRadius: 50, spreadRadius: 6),
                            ],
                          ),
                          child: Icon(slide.icon, size: 64, color: AppColors.white),
                        ),
                        const SizedBox(height: 40),
                        Text(slide.title, style: AppTextStyles.heading2(), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(slide.description,
                            style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: i == _index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.primaryPink : AppColors.textMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_index == _slides.length - 1) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(_index == _slides.length - 1 ? 'Get Started' : 'Next'),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
