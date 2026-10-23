import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/provider_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class ProviderDashboardScreen extends ConsumerWidget {
  const ProviderDashboardScreen({super.key, required this.provider});
  final ProviderModel provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderRepo = ref.watch(orderRepositoryProvider);
    final providerRepo = ref.watch(providerRepositoryProvider);

    return SafeArea(
      child: StreamBuilder<List<OrderModel>>(
        stream: orderRepo.watchProviderOrders(provider.id),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];
          final pending = orders.where((o) => o.orderStatus == OrderStatus.pending).length;
          final active = orders
              .where((o) => o.orderStatus != OrderStatus.completed && o.orderStatus != OrderStatus.cancelled)
              .length;
          final completed = orders.where((o) => o.orderStatus == OrderStatus.completed).length;
          final today = DateTime.now();
          final todaysJobs = orders
              .where((o) =>
                  o.scheduledDate.year == today.year &&
                  o.scheduledDate.month == today.month &&
                  o.scheduledDate.day == today.day)
              .length;
          final revenue = orders
              .where((o) => o.orderStatus == OrderStatus.completed)
              .fold<double>(0, (sum, o) => sum + o.totalAmount);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome', style: AppTextStyles.bodyMedium(color: AppColors.textMuted)),
                        Text(provider.providerName, style: AppTextStyles.heading2()),
                        const SizedBox(height: 4),
                        ProviderTypeBadge(type: provider.providerType, compact: true),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Switch(
                        value: provider.isAvailable,
                        onChanged: (v) => providerRepo.setAvailability(provider.id, v),
                      ),
                      Text(provider.isAvailable ? 'Available' : 'Unavailable',
                          style: AppTextStyles.caption()),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(label: 'Pending Orders', value: '$pending', icon: Icons.hourglass_top_rounded),
                  _StatCard(label: 'Active Orders', value: '$active', icon: Icons.local_shipping_rounded),
                  _StatCard(label: "Today's Jobs", value: '$todaysJobs', icon: Icons.today_rounded),
                  _StatCard(label: 'Completed', value: '$completed', icon: Icons.task_alt_rounded),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_rounded, color: AppColors.primaryPink, size: 32),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Revenue From Completed Orders', style: AppTextStyles.bodySmall()),
                          Text('KES ${revenue.toStringAsFixed(0)}', style: AppTextStyles.heading2(color: AppColors.primaryPink)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.star_rounded, color: AppColors.primaryPink),
                  title: Text('Provider Rating', style: AppTextStyles.bodyLarge()),
                  trailing: Text('${provider.rating.toStringAsFixed(1)} (${provider.reviewCount})',
                      style: AppTextStyles.bodyLarge(color: AppColors.primaryPink)),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_rounded, color: AppColors.primaryPink),
                  title: Text('Available Capacity', style: AppTextStyles.bodyLarge()),
                  trailing: Text('${provider.dailyCapacity} orders / day', style: AppTextStyles.bodyMedium()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryPink),
            const Spacer(),
            Text(value, style: AppTextStyles.heading2()),
            Text(label, style: AppTextStyles.bodySmall()),
          ],
        ),
      ),
    );
  }
}
