import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class ProviderOrdersScreen extends ConsumerWidget {
  const ProviderOrdersScreen({super.key, required this.providerId});
  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderRepo = ref.watch(orderRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PinkAppBar(
        title: 'Orders',
        subtitle: 'Every request from your customers',
        leadingIcon: Icons.receipt_long_rounded,
        showBack: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StreamBuilder(
              stream: orderRepo.watchProviderOrders(providerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Orders Yet',
                    message: 'New customer orders will appear here.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: orders.length,
                  itemBuilder: (context, i) {
                    final order = orders[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => context.push('${AppRoutes.providerHome}/order/${order.id}'),
                        title: Text(order.customerName, style: AppTextStyles.bodyLarge()),
                        subtitle: Text(
                          '${order.items.length} item(s) · ${DateFormat.yMMMd().format(order.createdAt)}',
                          style: AppTextStyles.bodySmall(),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            OrderStatusBadge(status: order.orderStatus),
                            const SizedBox(height: 4),
                            Text('KES ${order.totalAmount.toStringAsFixed(0)}', style: AppTextStyles.bodySmall()),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
