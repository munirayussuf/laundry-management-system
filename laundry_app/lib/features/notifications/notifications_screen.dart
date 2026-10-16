import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/notification_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_widgets.dart';

IconData iconForNotificationType(NotificationType type) {
  switch (type) {
    case NotificationType.newOrder:
      return Icons.receipt_long_rounded;
    case NotificationType.orderAccepted:
      return Icons.check_circle_rounded;
    case NotificationType.orderRejected:
      return Icons.cancel_rounded;
    case NotificationType.orderStatusChange:
      return Icons.sync_rounded;
    case NotificationType.paymentConfirmation:
      return Icons.payments_rounded;
    case NotificationType.orderCompleted:
      return Icons.task_alt_rounded;
    case NotificationType.cancellation:
      return Icons.block_rounded;
    case NotificationType.providerUpdate:
      return Icons.storefront_rounded;
    case NotificationType.general:
      return Icons.notifications_rounded;
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final repo = ref.watch(notificationRepositoryProvider);
    if (user == null) return const SizedBox.shrink();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(child: Text('Notifications', style: AppTextStyles.heading2())),
                TextButton(
                  onPressed: () => repo.markAllAsRead(user.uid),
                  child: const Text('Mark All Read'),
                ),
                TextButton(
                  onPressed: () async {
                    final confirmed = await showDeleteConfirmationDialog(
                      context,
                      title: 'Clear All Notifications',
                      message: 'Are you sure you want to delete all notifications? This action cannot be undone.',
                    );
                    if (confirmed) await repo.clearAll(user.uid);
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: repo.watchForUser(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final notifications = snapshot.data ?? [];
                if (notifications.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.notifications_off_outlined,
                    title: 'No Notifications',
                    message: 'You are all caught up.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: notifications.length,
                  itemBuilder: (context, i) {
                    final n = notifications[i];
                    return Dismissible(
                      key: ValueKey(n.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: AppColors.error),
                      ),
                      confirmDismiss: (_) => showDeleteConfirmationDialog(context),
                      onDismissed: (_) => repo.delete(n.id),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: n.isRead ? AppColors.surface : AppColors.surfaceAlt,
                        child: ListTile(
                          onTap: () => repo.markAsRead(n.id),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryPink.withOpacity(0.15),
                            child: Icon(iconForNotificationType(n.type), color: AppColors.primaryPink),
                          ),
                          title: Text(n.title, style: AppTextStyles.bodyLarge()),
                          subtitle: Text(n.body, style: AppTextStyles.bodySmall()),
                          trailing: Text(DateFormat.MMMd().add_jm().format(n.createdAt),
                              style: AppTextStyles.caption()),
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
