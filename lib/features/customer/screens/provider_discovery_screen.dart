import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/provider_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../widgets/provider_card.dart';

class ProviderDiscoveryScreen extends ConsumerStatefulWidget {
  const ProviderDiscoveryScreen({super.key});

  @override
  ConsumerState<ProviderDiscoveryScreen> createState() => _ProviderDiscoveryScreenState();
}

class _ProviderDiscoveryScreenState extends ConsumerState<ProviderDiscoveryScreen> {
  ProviderType? _providerType;
  WashingMethod? _washingMethod;
  IroningMethod? _ironingMethod;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(providerRepositoryProvider);
    final stream = _query.trim().isNotEmpty
        ? repo.searchProviders(_query.trim())
        : repo.discoverProviders(
            providerType: _providerType,
            washingMethod: _washingMethod,
            ironingMethod: _ironingMethod,
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PinkAppBar(
        title: 'Find A Provider',
        subtitle: 'Formal laundry and Mama Fua near you',
        leadingIcon: Icons.explore_rounded,
        showBack: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search by name or location',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All Types',
                  selected: _providerType == null,
                  onTap: () => setState(() => _providerType = null),
                ),
                _FilterChip(
                  label: ProviderType.formalLaundry.label,
                  selected: _providerType == ProviderType.formalLaundry,
                  onTap: () => setState(() => _providerType = ProviderType.formalLaundry),
                ),
                _FilterChip(
                  label: ProviderType.mamaFua.label,
                  selected: _providerType == ProviderType.mamaFua,
                  onTap: () => setState(() => _providerType = ProviderType.mamaFua),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: WashingMethod.machineWashing.label,
                  selected: _washingMethod == WashingMethod.machineWashing,
                  onTap: () => setState(() => _washingMethod =
                      _washingMethod == WashingMethod.machineWashing ? null : WashingMethod.machineWashing),
                ),
                _FilterChip(
                  label: WashingMethod.manualHandWashing.label,
                  selected: _washingMethod == WashingMethod.manualHandWashing,
                  onTap: () => setState(() => _washingMethod = _washingMethod ==
                          WashingMethod.manualHandWashing
                      ? null
                      : WashingMethod.manualHandWashing),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<ProviderModel>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ErrorStateView(message: snapshot.error.toString());
                }
                final providers = snapshot.data ?? [];
                if (providers.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No Providers Found',
                    message: 'Try a different filter or search term.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: providers.length,
                  itemBuilder: (context, i) => ProviderCard(provider: providers[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: AppTextStyles.bodySmall(color: selected ? AppColors.white : AppColors.textMuted),
      ),
    );
  }
}
