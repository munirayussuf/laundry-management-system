import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/provider_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class AdminProvidersScreen extends ConsumerStatefulWidget {
  const AdminProvidersScreen({super.key});

  @override
  ConsumerState<AdminProvidersScreen> createState() => _AdminProvidersScreenState();
}

class _AdminProvidersScreenState extends ConsumerState<AdminProvidersScreen> {
  ProviderType? _filter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(providerRepositoryProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Providers', style: AppTextStyles.heading2()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search providers',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(ProviderType.formalLaundry.label),
                  selected: _filter == ProviderType.formalLaundry,
                  onSelected: (_) => setState(() => _filter = ProviderType.formalLaundry),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(ProviderType.mamaFua.label),
                  selected: _filter == ProviderType.mamaFua,
                  onSelected: (_) => setState(() => _filter = ProviderType.mamaFua),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<ProviderModel>>(
              // Admins see inactive providers too, so onlyActive is false.
              stream: repo.discoverProviders(providerType: _filter, onlyActive: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final providers = (snapshot.data ?? [])
                    .where((p) => _query.isEmpty || p.providerName.toLowerCase().contains(_query))
                    .toList();
                if (providers.isEmpty) {
                  return const EmptyStateView(
                      icon: Icons.storefront_outlined, title: 'No Providers Found');
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: providers.length,
                  itemBuilder: (context, i) {
                    final provider = providers[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Text(provider.providerName, style: AppTextStyles.bodyLarge())),
                              if (provider.isVerified)
                                const Icon(Icons.verified_rounded, color: AppColors.primaryPink, size: 18),
                            ]),
                            const SizedBox(height: 6),
                            ProviderTypeBadge(type: provider.providerType, compact: true),
                            const SizedBox(height: 6),
                            Text('${provider.location} · ${provider.phone}',
                                style: AppTextStyles.bodySmall()),
                            const Divider(height: 20),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    await repo.setVerified(provider.id, !provider.isVerified);
                                    if (context.mounted) {
                                      showSuccessSnackBar(
                                        context,
                                        provider.isVerified
                                            ? 'Verification removed.'
                                            : 'Provider verified successfully.',
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.verified_outlined, size: 18),
                                  label: Text(provider.isVerified ? 'Remove Verification' : 'Verify'),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    await repo.setActive(provider.id, !provider.isActive);
                                    if (context.mounted) {
                                      showSuccessSnackBar(
                                        context,
                                        provider.isActive
                                            ? 'Provider deactivated.'
                                            : 'Provider activated.',
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    provider.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                    size: 18,
                                  ),
                                  label: Text(provider.isActive ? 'Deactivate' : 'Activate'),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                  onPressed: () async {
                                    final confirmed = await showDeleteConfirmationDialog(
                                      context,
                                      title: 'Delete This Provider',
                                      message:
                                          'Are you sure you want to delete ${provider.providerName}? This action cannot be undone.',
                                    );
                                    if (!confirmed) return;
                                    await repo.deleteProvider(provider.id);
                                    if (context.mounted) {
                                      showSuccessSnackBar(context, 'Provider deleted successfully.');
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  label: const Text('Delete'),
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
