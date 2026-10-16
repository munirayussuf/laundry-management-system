import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/order_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({super.key, required this.orderId});
  final String orderId;

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref, OrderModel order) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Cancel This Order',
      message: 'Are you sure you want to cancel this order? This action cannot be undone.',
    );
    if (!confirmed) return;
    await ref.read(orderRepositoryProvider).cancelOrder(order.id);
    await ref.read(smsServiceProvider).sendCancellation('', order.id);
    if (context.mounted) showSuccessSnackBar(context, 'Your order has been cancelled.');
  }

  Future<void> _openReviewSheet(BuildContext context, WidgetRef ref, OrderModel order) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    double rating = 5;
    final commentController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rate ${order.providerName}', style: AppTextStyles.heading3()),
                  const SizedBox(height: 16),
                  Center(
                    child: RatingBar.builder(
                      initialRating: 5,
                      minRating: 1,
                      itemCount: 5,
                      itemSize: 36,
                      itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: AppColors.primaryPink),
                      onRatingUpdate: (value) => setSheetState(() => rating = value),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Share your experience'),
                  ),
                  const SizedBox(height: 16),
                  PremiumButton(
                    label: 'Submit Review',
                    onPressed: () async {
                      try {
                        await ref.read(reviewRepositoryProvider).submitReview(
                              orderId: order.id,
                              customerId: user.uid,
                              customerName: user.name,
                              providerId: order.providerId,
                              rating: rating.round(),
                              comment: commentController.text.trim(),
                            );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          showSuccessSnackBar(context, 'Thank you for your review.');
                        }
                      } catch (e) {
                        if (context.mounted) showErrorSnackBar(context, e.toString());
                      }
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderRepo = ref.watch(orderRepositoryProvider);

    return Scaffold(
      appBar: const PinkAppBar(title: 'Order Tracking', subtitle: 'Follow your laundry in real time'),
      body: StreamBuilder<OrderModel?>(
        stream: orderRepo.watchOrder(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = snapshot.data;
          if (order == null) {
            return const ErrorStateView(message: 'This order could not be found.');
          }
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
                        Expanded(child: Text(order.providerName, style: AppTextStyles.heading3())),
                        OrderStatusBadge(status: order.orderStatus),
                      ]),
                      const SizedBox(height: 4),
                      Text('Order ID ${order.id.substring(0, 8).toUpperCase()}',
                          style: AppTextStyles.bodySmall()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Order Status Timeline', style: AppTextStyles.heading3()),
              const SizedBox(height: 12),
              if (order.orderStatus == OrderStatus.cancelled)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('This order was cancelled.'),
                )
              else
                _StatusTimeline(currentStatus: order.orderStatus),
              const SizedBox(height: 20),
              Text('Items', style: AppTextStyles.heading3()),
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
              Text('Payment Method: ${order.paymentMethod.label}', style: AppTextStyles.bodyMedium()),
              Text('Payment Status: ${order.paymentStatus.label}', style: AppTextStyles.bodyMedium()),
              const SizedBox(height: 12),
              if (order.pickupRequested)
                Text('Pickup: ${order.pickupAddress.label}', style: AppTextStyles.bodyMedium()),
              if (order.deliveryRequested)
                Text('Delivery: ${order.deliveryAddress.label}', style: AppTextStyles.bodyMedium()),
              if (order.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Notes', style: AppTextStyles.bodyLarge()),
                Text(order.notes, style: AppTextStyles.bodyMedium(color: AppColors.textMuted)),
              ],
              const SizedBox(height: 24),
              if (order.orderStatus == OrderStatus.pending)
                PremiumButton(
                  label: 'Cancel Order',
                  outlined: true,
                  onPressed: () => _cancelOrder(context, ref, order),
                ),
              if (order.orderStatus == OrderStatus.completed)
                PremiumButton(
                  label: 'Rate This Provider',
                  onPressed: () => _openReviewSheet(context, ref, order),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.currentStatus});
  final OrderStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    final lifecycle = OrderStatusX.lifecycle;
    final currentIndex = lifecycle.indexOf(currentStatus);

    return Column(
      children: List.generate(lifecycle.length, (i) {
        final reached = i <= currentIndex;
        final isLast = i == lifecycle.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reached ? AppColors.primaryPink : AppColors.surfaceAlt,
                    border: Border.all(color: reached ? AppColors.primaryPink : AppColors.textMuted),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 32,
                    color: reached ? AppColors.primaryPink : AppColors.surfaceAlt,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                lifecycle[i].label,
                style: reached
                    ? AppTextStyles.bodyLarge(color: AppColors.textPrimary)
                    : AppTextStyles.bodyMedium(color: AppColors.textMuted),
              ),
            ),
          ],
        );
      }),
    );
  }
}
