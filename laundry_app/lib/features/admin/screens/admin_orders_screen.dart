import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/order_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  OrderStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('All Orders', style: AppTextStyles.heading2()),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                ...OrderStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s.label),
                        selected: _filter == s,
                        onSelected: (_) => setState(() => _filter = s),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(FirestorePaths.orders)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const ErrorStateView(message: 'Could not load orders.');
                }
                final orders = (snapshot.data?.docs ?? [])
                    .map((d) => OrderModel.fromMap(d.id, d.data()))
                    .where((o) => _filter == null || o.orderStatus == _filter)
                    .toList();
                if (orders.isEmpty) {
                  return const EmptyStateView(
                      icon: Icons.receipt_long_outlined, title: 'No Orders Found');
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: orders.length,
                  itemBuilder: (context, i) {
                    final order = orders[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text('${order.customerName} to ${order.providerName}',
                            style: AppTextStyles.bodyLarge()),
                        subtitle: Text(
                          '${DateFormat.yMMMd().format(order.createdAt)} · KES ${order.totalAmount.toStringAsFixed(0)} · ${order.paymentStatus.label}',
                          style: AppTextStyles.bodySmall(),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OrderStatusBadge(status: order.orderStatus),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              onPressed: () async {
                                final confirmed = await showDeleteConfirmationDialog(
                                  context,
                                  title: 'Delete This Order',
                                  message:
                                      'Are you sure you want to delete this order record? This action cannot be undone.',
                                );
                                if (!confirmed) return;
                                await ref.read(orderRepositoryProvider).deleteOrder(order.id);
                                if (context.mounted) {
                                  showSuccessSnackBar(context, 'Order deleted successfully.');
                                }
                              },
                            ),
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
