import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/support_message_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class AdminSupportScreen extends ConsumerWidget {
  const AdminSupportScreen({super.key});

  Future<void> _toggleStatus(
    BuildContext context,
    WidgetRef ref,
    SupportMessageModel message,
  ) async {
    try {
      await ref
          .read(supportRepositoryProvider)
          .setResolved(message.id, message.status != 'resolved');
      if (context.mounted) {
        showSuccessSnackBar(
          context,
          message.status == 'resolved'
              ? 'Message reopened.'
              : 'Message marked as resolved.',
        );
      }
    } catch (error) {
      if (context.mounted) {
        showErrorSnackBar(
          context,
          'Could not update this message. Check the connection and try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Support Inbox', style: AppTextStyles.heading2()),
          ),
          Expanded(
            child: StreamBuilder<List<SupportMessageModel>>(
              stream: ref.read(supportRepositoryProvider).watchMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const ErrorStateView(
                    message:
                        'Could not load the support inbox. Try again later.',
                  );
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.support_agent,
                    title: 'No Support Messages',
                    message:
                        'Customer concerns sent from the app will appear here.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final resolved = message.status == 'resolved';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    message.subject,
                                    style: AppTextStyles.bodyLarge(),
                                  ),
                                ),
                                Icon(
                                  resolved
                                      ? Icons.check_circle
                                      : Icons.mark_email_unread_outlined,
                                  color: resolved
                                      ? Colors.green
                                      : AppColors.primaryPink,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${message.name} · ${message.email}',
                              style: AppTextStyles.bodySmall(),
                            ),
                            const SizedBox(height: 10),
                            Text(message.message),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  resolved ? 'Resolved' : 'Open',
                                  style: AppTextStyles.bodySmall(
                                    color: resolved
                                        ? Colors.green
                                        : AppColors.primaryPink,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () =>
                                      _toggleStatus(context, ref, message),
                                  child: Text(
                                    resolved ? 'Reopen' : 'Mark resolved',
                                  ),
                                ),
                              ],
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
