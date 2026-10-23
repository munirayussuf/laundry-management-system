import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

/// Registration form for a laundry provider profile. Both Formal Laundry
/// businesses and Mama Fua / Jua Kali operators use this same screen, since
/// they are equally first class citizens of the provider database; only the
/// provider type selection differs.
class ProviderRegistrationScreen extends ConsumerStatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  ConsumerState<ProviderRegistrationScreen> createState() => _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState extends ConsumerState<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _turnaroundController = TextEditingController(text: '24');
  final _capacityController = TextEditingController(text: '10');
  ProviderType _providerType = ProviderType.mamaFua;
  WashingMethod _washingMethod = WashingMethod.manualHandWashing;
  IroningMethod _ironingMethod = IroningMethod.electricIron;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(providerRepositoryProvider).registerProvider(
            ownerId: user.uid,
            providerName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: user.email,
            providerType: _providerType,
            washingMethod: _washingMethod,
            ironingMethod: _ironingMethod,
            description: _descriptionController.text.trim(),
            location: _locationController.text.trim(),
            startingPrice: double.tryParse(_priceController.text.trim()) ?? 0,
            turnaroundHours: int.tryParse(_turnaroundController.text.trim()) ?? 24,
            dailyCapacity: int.tryParse(_capacityController.text.trim()) ?? 10,
          );
      if (mounted) showSuccessSnackBar(context, 'Your provider profile has been created.');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Could not create your provider profile. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PinkAppBar(title: 'Provider Registration', subtitle: 'Set up your laundry profile'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Tell Us About Your Business', style: AppTextStyles.heading2()),
              const SizedBox(height: 4),
              Text(
                'Complete your profile so customers can discover and book your laundry services.',
                style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              Text('Provider Type', style: AppTextStyles.heading3()),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: _TypeCard(
                    label: ProviderType.formalLaundry.label,
                    icon: Icons.local_laundry_service_rounded,
                    selected: _providerType == ProviderType.formalLaundry,
                    onTap: () => setState(() => _providerType = ProviderType.formalLaundry),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeCard(
                    label: ProviderType.mamaFua.label,
                    icon: Icons.handshake_rounded,
                    selected: _providerType == ProviderType.mamaFua,
                    onTap: () => setState(() => _providerType = ProviderType.mamaFua),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Business Or Provider Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', hintText: '0712345678'),
                validator: (v) {
                  final regex = RegExp(r'^(?:\+254|0)[17]\d{8}$');
                  return (v == null || !regex.hasMatch(v.trim())) ? 'Enter a valid Kenyan phone number' : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Location is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
              ),
              const SizedBox(height: 20),
              Text('Washing Method', style: AppTextStyles.heading3()),
              const SizedBox(height: 8),
              Wrap(spacing: 10, children: WashingMethod.values.map((m) {
                return ChoiceChip(
                  label: Text(m.label),
                  selected: _washingMethod == m,
                  onSelected: (_) => setState(() => _washingMethod = m),
                );
              }).toList()),
              const SizedBox(height: 20),
              Text('Ironing Method', style: AppTextStyles.heading3()),
              const SizedBox(height: 8),
              Wrap(spacing: 10, children: IroningMethod.values.map((m) {
                return ChoiceChip(
                  label: Text(m.label),
                  selected: _ironingMethod == m,
                  onSelected: (_) => setState(() => _ironingMethod = m),
                );
              }).toList()),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Starting Price (KES)'),
                    validator: (v) {
                      final value = double.tryParse(v ?? '');
                      if (value == null || value < 0) return 'Enter a valid price';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _turnaroundController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Turnaround (Hours)'),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Daily Capacity'),
                validator: (v) {
                  final value = int.tryParse(v ?? '');
                  if (value == null || value <= 0) return 'Enter a valid capacity';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              PremiumButton(label: 'Create Provider Profile', isLoading: _isSubmitting, onPressed: _submit),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.softPink : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primaryPink : AppColors.border),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? AppColors.primaryPink : AppColors.textMuted),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall(
                  color: selected ? AppColors.primaryPink : AppColors.textBody)),
        ]),
      ),
    );
  }
}
