import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_enums.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.role});
  final UserRole role;

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final locationController = TextEditingController(text: user.location);
    await showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Edit Profile'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')), const SizedBox(height: 12), TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number')), const SizedBox(height: 12), TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () async { await ref.read(authServiceProvider).updateProfile(name: nameController.text, phone: phoneController.text, location: locationController.text); if (context.mounted) { Navigator.pop(context); showSuccessSnackBar(context, 'Profile updated successfully.'); } }, child: const Text('Save'))]));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final authService = ref.watch(authServiceProvider);

    if (user == null) return const SizedBox.shrink();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.surfaceAlt,
                  backgroundImage: user.profileImage.isNotEmpty ? NetworkImage(user.profileImage) : null,
                  child: user.profileImage.isEmpty
                      ? const Icon(Icons.person, size: 44, color: AppColors.primaryPink)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(user.name, style: AppTextStyles.heading2()),
                Text(user.email, style: AppTextStyles.bodySmall()),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_outlined, color: AppColors.primaryPink),
                  title: const Text('Phone Number'),
                  subtitle: Text(user.phone.isEmpty ? 'Not set' : user.phone),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: AppColors.primaryPink),
                  title: const Text('Location'),
                  subtitle: Text(user.location.isEmpty ? 'Not set' : user.location),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: AppColors.primaryPink),
                  title: const Text('Edit Profile'),
                  onTap: () => _editProfile(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.notifications_active_outlined, color: AppColors.primaryPink),
                  title: Text('Notification Settings'),
                ),
                const ListTile(
                  leading: Icon(Icons.privacy_tip_outlined, color: AppColors.primaryPink),
                  title: Text('Privacy'),
                ),
                const ListTile(
                  leading: Icon(Icons.description_outlined, color: AppColors.primaryPink),
                  title: Text('Terms Of Service'),
                ),
                const ListTile(
                  leading: Icon(Icons.help_outline, color: AppColors.primaryPink),
                  title: Text('Help And Support'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PremiumButton(
            label: 'Logout',
            outlined: true,
            onPressed: () => authService.logout(),
          ),
        ],
      ),
    );
  }
}
