import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/service_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

const _pricingUnits = [
  'per kilogram',
  'per piece',
  'per load',
  'per basket',
  'per order',
];

class ProviderServicesScreen extends ConsumerWidget {
  const ProviderServicesScreen({super.key, required this.providerId});
  final String providerId;

  Future<void> _openServiceSheet(
    BuildContext context,
    WidgetRef ref, {
    ServiceModel? existing,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descriptionController = TextEditingController(text: existing?.description ?? '');
    final priceController =
        TextEditingController(text: existing != null ? existing.price.toStringAsFixed(0) : '');
    String pricingUnit = existing?.pricingUnit ?? _pricingUnits.first;
    bool isAvailable = existing?.isAvailable ?? true;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existing == null ? 'Add Service' : 'Edit Service',
                        style: AppTextStyles.heading3()),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Service Name'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Service name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (KES)'),
                      validator: (v) {
                        final value = double.tryParse(v ?? '');
                        if (value == null) return 'Enter a valid price';
                        if (value < 0) return 'Price cannot be negative';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: pricingUnit,
                      decoration: const InputDecoration(labelText: 'Pricing Unit'),
                      dropdownColor: AppColors.surfaceAlt,
                      items: _pricingUnits
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setSheetState(() => pricingUnit = v ?? pricingUnit),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available For Booking'),
                      value: isAvailable,
                      onChanged: (v) => setSheetState(() => isAvailable = v),
                    ),
                    const SizedBox(height: 12),
                    PremiumButton(
                      label: existing == null ? 'Add Service' : 'Save Changes',
                      isLoading: isSaving,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheetState(() => isSaving = true);
                        final repo = ref.read(providerRepositoryProvider);
                        try {
                          if (existing == null) {
                            await repo.addService(
                              providerId: providerId,
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                              price: double.parse(priceController.text.trim()),
                              pricingUnit: pricingUnit,
                            );
                          } else {
                            await repo.editService(
                              providerId,
                              existing.copyWith(
                                name: nameController.text.trim(),
                                description: descriptionController.text.trim(),
                                price: double.parse(priceController.text.trim()),
                                pricingUnit: pricingUnit,
                                isAvailable: isAvailable,
                              ),
                            );
                          }
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            showSuccessSnackBar(
                              context,
                              existing == null
                                  ? 'Service added successfully.'
                                  : 'Service updated successfully.',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showErrorSnackBar(context, 'Could not save the service. Please try again.');
                          }
                        } finally {
                          setSheetState(() => isSaving = false);
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
    );
  }

  Future<void> _deleteService(BuildContext context, WidgetRef ref, ServiceModel service) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Delete This Service',
      message: 'Are you sure you want to delete ${service.name}? This action cannot be undone.',
    );
    if (!confirmed) return;
    try {
      await ref.read(providerRepositoryProvider).deleteService(providerId, service.id);
      if (context.mounted) showSuccessSnackBar(context, 'Service deleted successfully.');
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, 'Could not delete the service. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(providerRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryPink,
        onPressed: () => _openServiceSheet(context, ref),
        icon: const Icon(Icons.add, color: AppColors.white),
        label: Text('Add Service', style: AppTextStyles.buttonLabel(color: AppColors.white)),
      ),
      appBar: const PinkAppBar(
        title: 'My Services',
        subtitle: 'Manage what you offer and your prices',
        leadingIcon: Icons.cleaning_services_rounded,
        showBack: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StreamBuilder<List<ServiceModel>>(
                stream: repo.watchServices(providerId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ErrorStateView(message: snapshot.error.toString());
                  }
                  final services = snapshot.data ?? [];
                  if (services.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.cleaning_services_outlined,
                      title: 'No Services Yet',
                      message: 'Add the laundry services you offer so customers can book them.',
                      actionLabel: 'Add Service',
                      onAction: () => _openServiceSheet(context, ref),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                    itemCount: services.length,
                    itemBuilder: (context, i) {
                      final service = services[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Row(children: [
                            Expanded(child: Text(service.name, style: AppTextStyles.bodyLarge())),
                            if (!service.isAvailable)
                              Text('Paused', style: AppTextStyles.caption(color: AppColors.warning)),
                          ]),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (service.description.isNotEmpty)
                                Text(service.description, style: AppTextStyles.bodySmall()),
                              Text('KES ${service.price.toStringAsFixed(0)} ${service.pricingUnit}',
                                  style: AppTextStyles.bodySmall(color: AppColors.primaryPink)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primaryPink),
                                onPressed: () => _openServiceSheet(context, ref, existing: service),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => _deleteService(context, ref, service),
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
      ),
    );
  }
}
