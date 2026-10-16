import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/models/order_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class ProviderOrderDetailsScreen extends ConsumerStatefulWidget {
  const ProviderOrderDetailsScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<ProviderOrderDetailsScreen> createState() => _ProviderOrderDetailsScreenState();
}

class _ProviderOrderDetailsScreenState extends ConsumerState<ProviderOrderDetailsScreen> {
  bool _isUpdating = false;

  /// Returns the next status in the lifecycle, or null when the order has
  /// already reached completion.
  OrderStatus? _nextStatus(OrderStatus current) {
    final lifecycle = OrderStatusX.lifecycle;
    final index = lifecycle.indexOf(current);
    if (index < 0 || index >= lifecycle.length - 1) return null;
    return lifecycle[index + 1];
  }

  Future<void> _advance(OrderModel order, OrderStatus next) async {
    setState(() => _isUpdating = true);
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      await orderRepo.updateStatus(order.id, next);

      await ref.read(notificationRepositoryProvider).create(
            userId: order.customerId,
            title: 'Order ${next.label}',
            body: 'Your order with ${order.providerName} is now ${next.label}.',
            type: next == OrderStatus.accepted
                ? NotificationType.orderAccepted
                : next == OrderStatus.completed
                    ? NotificationType.orderCompleted
                    : NotificationType.orderStatusChange,
            relatedOrderId: order.id,
          );

      // Cash on delivery is settled when the provider completes the order.
      if (next == OrderStatus.completed && order.paymentMethod == PaymentMethod.cashOnDelivery) {
        await orderRepo.updatePaymentStatus(order.id, PaymentStatus.paid);
      }

      if (mounted) showSuccessSnackBar(context, 'Order status updated to ${next.label}.');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Could not update the order status. Please try again.');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _reject(OrderModel order) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Reject This Order',
      message: 'Are you sure you want to reject this order? The customer will be notified.',
    );
    if (!confirmed) return;

    setState(() => _isUpdating = true);
    try {
      await ref.read(orderRepositoryProvider).cancelOrder(order.id);
      await ref.read(notificationRepositoryProvider).create(
            userId: order.customerId,
            title: 'Order Rejected',
            body: '${order.providerName} could not take on your order at this time.',
            type: NotificationType.orderRejected,
            relatedOrderId: order.id,
          );
      if (mounted) showSuccessSnackBar(context, 'The order has been rejected.');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Could not reject this order. Please try again.');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderRepo = ref.watch(orderRepositoryProvider);

    return Scaffold(
      appBar: const PinkAppBar(title: 'Order Details', subtitle: 'Review and update this order'),
      body: StreamBuilder<OrderModel?>(
        stream: orderRepo.watchOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = snapshot.data;
          if (order == null) {
            return const ErrorStateView(message: 'This order could not be found.');
          }

          final next = _nextStatus(order.orderStatus);
          final isClosed = order.orderStatus == OrderStatus.completed ||
              order.orderStatus == OrderStatus.cancelled;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(order.customerName, style: AppTextStyles.heading3())),
                        OrderStatusBadge(status: order.orderStatus),
                      ]),
                      const SizedBox(height: 4),
                      Text('Order ID ${order.id.substring(0, 8).toUpperCase()}',
                          style: AppTextStyles.bodySmall()),
                      const SizedBox(height: 4),
                      Text('Placed ${DateFormat.yMMMd().add_jm().format(order.createdAt)}',
                          style: AppTextStyles.bodySmall()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Requested Services', style: AppTextStyles.heading3()),
              const SizedBox(height: 8),
              ...order.items.map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.serviceName),
                    subtitle: Text('${item.quantity.toStringAsFixed(0)} ${item.pricingUnit}'),
                    trailing: Text('KES ${item.lineTotal.toStringAsFixed(0)}'),
                  )),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Total Amount', style: AppTextStyles.bodyLarge()),
                trailing: Text('KES ${order.totalAmount.toStringAsFixed(0)}',
                    style: AppTextStyles.heading3(color: AppColors.primaryPink)),
              ),
              const SizedBox(height: 12),
              _DetailRow(icon: Icons.local_laundry_service_outlined, label: order.washingMethod.label),
              _DetailRow(icon: Icons.iron_outlined, label: order.ironingMethod.label),
              if (order.pickupRequested)
                _DetailRow(icon: Icons.my_location, label: 'Pickup: ${order.pickupAddress.label}'),
              if (order.deliveryRequested)
                _DetailRow(icon: Icons.flag_outlined, label: 'Delivery: ${order.deliveryAddress.label}'),
              _DetailRow(
                icon: Icons.event,
                label: 'Scheduled ${DateFormat.yMMMd().format(order.scheduledDate)} at ${order.scheduledTime}',
              ),
              _DetailRow(icon: Icons.payments_outlined, label: order.paymentMethod.label),
              if (order.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Customer Notes', style: AppTextStyles.bodyLarge()),
                Text(order.notes, style: AppTextStyles.bodyMedium(color: AppColors.textMuted)),
              ],
              const SizedBox(height: 28),
              if (!isClosed && next != null)
                PremiumButton(
                  label: order.orderStatus == OrderStatus.pending
                      ? 'Accept Order'
                      : 'Mark As ${next.label}',
                  isLoading: _isUpdating,
                  onPressed: () => _advance(order, next),
                ),
              if (order.orderStatus == OrderStatus.pending) ...[
                const SizedBox(height: 12),
                PremiumButton(
                  label: 'Reject Order',
                  outlined: true,
                  isLoading: _isUpdating,
                  onPressed: () => _reject(order),
                ),
              ],
              if (isClosed)
                Center(
                  child: Text(
                    order.orderStatus == OrderStatus.completed
                        ? 'This order has been completed.'
                        : 'This order was cancelled.',
                    style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.primaryPink),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium())),
      ]),
    );
  }
}
