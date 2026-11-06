import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_enums.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/profile_image_provider.dart';
import '../../core/widgets/app_widgets.dart';

const _ussdShortcode = String.fromEnvironment('USSD_SHORTCODE');

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.role});
  final UserRole role;

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final locationController = TextEditingController(text: user.location);
    var profileImage = user.profileImage;
    var saving = false;
    double? latitude = user.latitude;
    double? longitude = user.longitude;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundImage: profileImageProvider(profileImage),
                    child: profileImage.isEmpty
                        ? const Icon(Icons.person, size: 34)
                        : null,
                  ),
                  TextButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            try {
                              final photo = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 512,
                                maxHeight: 512,
                                imageQuality: 65,
                              );
                              if (photo == null) return;
                              final bytes = await photo.readAsBytes();
                              setDialogState(() {
                                profileImage =
                                    'data:image/jpeg;base64,${base64Encode(bytes)}';
                              });
                            } catch (error) {
                              if (context.mounted) {
                                showErrorSnackBar(
                                  context,
                                  'Could not open your photos. Please check app permissions.',
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Change profile photo'),
                  ),
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (value) =>
                        value == null || value.trim().length < 2
                            ? 'Enter your name'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Phone Number'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your phone number'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationController,
                    onChanged: (_) {
                      latitude = null;
                      longitude = null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'Type a location or use GPS below',
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              try {
                                final position =
                                    await LocationService().currentPosition();
                                setDialogState(() {
                                  locationController.text =
                                      LocationService().describe(position);
                                  latitude = position.latitude;
                                  longitude = position.longitude;
                                });
                              } catch (error) {
                                if (context.mounted) {
                                  showErrorSnackBar(
                                    context,
                                    error is StateError
                                        ? error.message.toString()
                                        : 'Unable to read your location. Check your phone settings and try again.',
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use current phone location'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => saving = true);
                      try {
                        final location = locationController.text.trim();
                        await ref.read(authServiceProvider).updateProfile(
                              name: nameController.text,
                              phone: phoneController.text,
                              location: location,
                              profileImage: profileImage,
                              latitude: latitude,
                              longitude: longitude,
                            );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          showSuccessSnackBar(
                              context, 'Profile updated successfully.');
                        }
                      } catch (error) {
                        if (context.mounted) {
                          showErrorSnackBar(
                            context,
                            'Profile update failed. Please check your connection and try again.',
                          );
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => saving = false);
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    phoneController.dispose();
    locationController.dispose();
  }

  Future<void> _sendSupportMessage(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    var sending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Help and Support'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Write your concern here. It will be sent securely to the admin support inbox.',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: subjectController,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    validator: (value) =>
                        value == null || value.trim().length < 3
                            ? 'Enter a short subject'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: messageController,
                    minLines: 4,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: 'How can we help?',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 10
                            ? 'Please provide at least 10 characters'
                            : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => sending = true);
                      try {
                        await ref.read(supportRepositoryProvider).sendMessage(
                              subject: subjectController.text,
                              message: messageController.text,
                            );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          showSuccessSnackBar(
                            context,
                            'Your message was sent to the admin support inbox.',
                          );
                        }
                      } catch (error) {
                        if (context.mounted) {
                          showErrorSnackBar(
                            context,
                            'Message could not be sent. Check your connection and try again.',
                          );
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => sending = false);
                        }
                      }
                    },
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send to Admin'),
            ),
          ],
        ),
      ),
    );

    subjectController.dispose();
    messageController.dispose();
  }

  void _showInformation(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCurrentLocation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    try {
      final position = await LocationService().currentPosition();
      await ref.read(authServiceProvider).updateProfile(
            name: user.name,
            phone: user.phone,
            location: LocationService().describe(position),
            latitude: position.latitude,
            longitude: position.longitude,
          );
      if (context.mounted) {
        showSuccessSnackBar(context, 'Your exact location has been saved.');
      }
    } catch (error) {
      if (context.mounted) {
        showErrorSnackBar(
          context,
          error is StateError
              ? error.message.toString()
              : 'Unable to save your location. Please try again.',
        );
      }
    }
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
                  backgroundImage: profileImageProvider(user.profileImage),
                  child: user.profileImage.isEmpty
                      ? const Icon(Icons.person,
                          size: 44, color: AppColors.primaryPink)
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
                  leading: const Icon(Icons.phone_outlined,
                      color: AppColors.primaryPink),
                  title: const Text('Phone Number'),
                  subtitle: Text(user.phone.isEmpty ? 'Not set' : user.phone),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined,
                      color: AppColors.primaryPink),
                  title: const Text('Location'),
                  subtitle:
                      Text(user.location.isEmpty ? 'Not set' : user.location),
                  trailing: IconButton(
                    tooltip: 'Use exact phone location',
                    onPressed: () => _updateCurrentLocation(context, ref),
                    icon: const Icon(Icons.gps_fixed,
                        color: AppColors.primaryPink),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined,
                      color: AppColors.primaryPink),
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
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined,
                      color: AppColors.primaryPink),
                  title: const Text('Notification Settings'),
                  subtitle: const Text(
                      'Order updates appear in the Notifications tab.'),
                  onTap: () => _showInformation(
                    context,
                    title: 'Notifications',
                    body:
                        'Order updates and service messages are available in the Notifications tab. '
                        'Allow Laundry Service notifications in your phone settings to receive system alerts.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined,
                      color: AppColors.primaryPink),
                  title: const Text('Privacy'),
                  onTap: () => _showInformation(
                    context,
                    title: 'Privacy',
                    body:
                        'Your profile details and location are used to manage bookings and show nearby laundry providers. '
                        'Location is requested only when you choose to use it. Contact admin support to ask about your account data.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined,
                      color: AppColors.primaryPink),
                  title: const Text('Terms Of Service'),
                  onTap: () => _showInformation(
                    context,
                    title: 'Terms of Service',
                    body:
                        'Provide accurate booking and contact details. Providers are responsible for confirming service, '
                        'pricing and collection arrangements. Contact admin support if a booking or payment needs review.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline,
                      color: AppColors.primaryPink),
                  title: const Text('Help And Support'),
                  subtitle:
                      const Text('Send a concern directly to the admin team.'),
                  onTap: () => _sendSupportMessage(context, ref),
                ),
                if (_ussdShortcode.isNotEmpty)
                  ListTile(
                    leading:
                        const Icon(Icons.dialpad, color: AppColors.primaryPink),
                    title: const Text('USSD for feature phones'),
                    subtitle: const Text('Dial $_ussdShortcode'),
                    onTap: () => _showInformation(
                      context,
                      title: 'USSD access',
                      body:
                          'Dial $_ussdShortcode from a feature phone to find providers, book a service and check an order.',
                    ),
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
