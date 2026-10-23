import 'package:flutter/material.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/profile_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_providers_screen.dart';
import 'admin_orders_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _screens = [
    AdminDashboardScreen(),
    AdminUsersScreen(),
    AdminProvidersScreen(),
    AdminOrdersScreen(),
    ProfileScreen(role: UserRole.admin),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'Providers'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
