import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/provider_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/notifications_screen.dart';
import '../../profile/profile_screen.dart';
import 'provider_dashboard_screen.dart';
import 'provider_orders_screen.dart';
import 'provider_services_screen.dart';
import 'provider_registration_screen.dart';

class ProviderShell extends ConsumerStatefulWidget {
  const ProviderShell({super.key});

  @override
  ConsumerState<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends ConsumerState<ProviderShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final providerRepo = ref.watch(providerRepositoryProvider);

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<ProviderModel?>(
      stream: providerRepo.watchProvider(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final provider = snapshot.data;
        if (provider == null) {
          // First time provider: prompt full business registration before
          // unlocking the dashboard, exactly as section 14 requires.
          return const ProviderRegistrationScreen();
        }

        final screens = [
          ProviderDashboardScreen(provider: provider),
          ProviderOrdersScreen(providerId: provider.id),
          ProviderServicesScreen(providerId: provider.id),
          const NotificationsScreen(),
          const ProfileScreen(role: UserRole.provider),
        ];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: IndexedStack(index: _index, children: screens),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
              BottomNavigationBarItem(icon: Icon(Icons.cleaning_services_rounded), label: 'Services'),
              BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Notifications'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}
