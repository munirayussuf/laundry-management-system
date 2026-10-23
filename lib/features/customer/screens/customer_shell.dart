import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import 'customer_home_screen.dart';
import 'provider_discovery_screen.dart';
import 'my_orders_screen.dart';
import '../../notifications/notifications_screen.dart';
import '../../profile/profile_screen.dart';

class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key});

  static const _screens = [
    CustomerHomeScreen(),
    ProviderDiscoveryScreen(),
    MyOrdersScreen(),
    NotificationsScreen(),
    ProfileScreen(role: UserRole.customer),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(customerTabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => ref.read(customerTabIndexProvider.notifier).state = i,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
