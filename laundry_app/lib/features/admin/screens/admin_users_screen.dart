import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _query = '';

  Future<void> _setActive(UserModel user, bool isActive) async {
    await FirebaseFirestore.instance
        .collection(FirestorePaths.users)
        .doc(user.uid)
        .update({'isActive': isActive, 'updatedAt': Timestamp.now()});
    if (mounted) {
      showSuccessSnackBar(
        context,
        isActive ? 'Account activated successfully.' : 'Account deactivated successfully.',
      );
    }
  }

  /// Deletes the user profile document. Note that removing the underlying
  /// Firebase Authentication account requires the Admin SDK and is handled
  /// by the deleteUserAccount Cloud Function described in the README.
  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Delete This User',
      message: 'Are you sure you want to delete ${user.name}? This action cannot be undone.',
    );
    if (!confirmed) return;
    await FirebaseFirestore.instance.collection(FirestorePaths.users).doc(user.uid).delete();
    if (mounted) showSuccessSnackBar(context, 'User deleted successfully.');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Users', style: AppTextStyles.heading2()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection(FirestorePaths.users).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const ErrorStateView(message: 'Could not load users.');
                }
                final users = (snapshot.data?.docs ?? [])
                    .map((d) => UserModel.fromMap(d.id, d.data()))
                    .where((u) =>
                        _query.isEmpty ||
                        u.name.toLowerCase().contains(_query) ||
                        u.email.toLowerCase().contains(_query))
                    .toList();

                if (users.isEmpty) {
                  return const EmptyStateView(icon: Icons.people_outline, title: 'No Users Found');
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final user = users[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surfaceAlt,
                          child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: AppTextStyles.bodyLarge(color: AppColors.primaryPink)),
                        ),
                        title: Text(user.name, style: AppTextStyles.bodyLarge()),
                        subtitle: Text('${user.email} · ${user.role.value}',
                            style: AppTextStyles.bodySmall()),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: user.isActive,
                              onChanged: (v) => _setActive(user, v),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              onPressed: () => _deleteUser(user),
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
