import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_enums.dart';
import '../providers/app_providers.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/customer/screens/customer_shell.dart';
import '../../features/customer/screens/provider_details_screen.dart';
import '../../features/customer/screens/booking_screen.dart';
import '../../features/customer/screens/order_details_screen.dart';
import '../../features/provider/screens/provider_shell.dart';
import '../../features/provider/screens/provider_registration_screen.dart';
import '../../features/provider/screens/provider_order_details_screen.dart';
import '../../features/admin/screens/admin_shell.dart';

class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  static const customerHome = '/customer';
  static const providerDetails = '/customer/provider';
  static const booking = '/customer/booking';
  static const orderDetails = '/customer/order';

  static const providerHome = '/provider';
  static const providerRegistration = '/provider/register';
  static const providerOrderDetails = '/provider/order';

  static const adminHome = '/admin';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final userAsync = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _RiverpodRefreshStream(ref),
    redirect: (context, state) {
      final atPublicRoute = <String>{
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      }.contains(state.matchedLocation);

      return userAsync.when(
        loading: () => null,
        error: (_, __) => atPublicRoute ? null : AppRoutes.login,
        data: (user) {
          if (user == null) {
            return atPublicRoute ? null : AppRoutes.login;
          }

          // Signed in users should never linger on auth screens.
          final onAuthScreen = <String>{
            AppRoutes.splash,
            AppRoutes.onboarding,
            AppRoutes.login,
            AppRoutes.register,
            AppRoutes.forgotPassword,
          }.contains(state.matchedLocation);

          final homeForRole = switch (user.role) {
            UserRole.customer => AppRoutes.customerHome,
            UserRole.provider => AppRoutes.providerHome,
            UserRole.admin => AppRoutes.adminHome,
          };

          if (onAuthScreen) return homeForRole;

          // Enforce that customers can never reach provider or admin
          // screens, and providers can never reach admin screens.
          final goingToProvider = state.matchedLocation.startsWith(AppRoutes.providerHome);
          final goingToAdmin = state.matchedLocation.startsWith(AppRoutes.adminHome);
          final goingToCustomer = state.matchedLocation.startsWith(AppRoutes.customerHome);

          if (user.role == UserRole.customer && (goingToProvider || goingToAdmin)) {
            return AppRoutes.customerHome;
          }
          if (user.role == UserRole.provider && (goingToAdmin || goingToCustomer)) {
            return AppRoutes.providerHome;
          }
          if (user.role == UserRole.admin && (goingToProvider || goingToCustomer)) {
            return AppRoutes.adminHome;
          }
          return null;
        },
      );
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (c, s) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (c, s) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (c, s) => const RegisterScreen()),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (c, s) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerHome,
        builder: (c, s) => const CustomerShell(),
        routes: [
          GoRoute(
            path: 'provider/:providerId',
            builder: (c, s) => ProviderDetailsScreen(providerId: s.pathParameters['providerId']!),
          ),
          GoRoute(
            path: 'booking/:providerId',
            builder: (c, s) => BookingScreen(providerId: s.pathParameters['providerId']!),
          ),
          GoRoute(
            path: 'order/:orderId',
            builder: (c, s) => OrderDetailsScreen(orderId: s.pathParameters['orderId']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.providerHome,
        builder: (c, s) => const ProviderShell(),
        routes: [
          GoRoute(
            path: 'register',
            builder: (c, s) => const ProviderRegistrationScreen(),
          ),
          GoRoute(
            path: 'order/:orderId',
            builder: (c, s) =>
                ProviderOrderDetailsScreen(orderId: s.pathParameters['orderId']!),
          ),
        ],
      ),
      GoRoute(path: AppRoutes.adminHome, builder: (c, s) => const AdminShell()),
    ],
  );
});

/// Bridges a Riverpod stream provider into a Listenable so GoRouter can
/// re-evaluate its redirect callback whenever auth state changes.
class _RiverpodRefreshStream extends ChangeNotifier {
  _RiverpodRefreshStream(Ref ref) {
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
}
