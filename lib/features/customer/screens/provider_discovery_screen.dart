import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/provider_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../widgets/provider_card.dart';

class ProviderDiscoveryScreen extends ConsumerStatefulWidget {
  const ProviderDiscoveryScreen({super.key});

  @override
  ConsumerState<ProviderDiscoveryScreen> createState() =>
      _ProviderDiscoveryScreenState();
}

class _ProviderDiscoveryScreenState
    extends ConsumerState<ProviderDiscoveryScreen> {
  ProviderType? _providerType;
  WashingMethod? _washingMethod;
  IroningMethod? _ironingMethod;
  final _searchController = TextEditingController();
  String _query = '';
  bool _nearbyEnabled = false;
  int _retryVersion = 0;

  Future<void> _useCurrentLocation() async {
    try {
      final position = await LocationService().currentPosition();
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) {
        throw StateError('Sign in before saving your location.');
      }
      await ref.read(authServiceProvider).updateProfile(
            name: user.name,
            phone: user.phone,
            location: LocationService().describe(position),
            latitude: position.latitude,
            longitude: position.longitude,
          );
      if (mounted) setState(() => _nearbyEnabled = true);
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          error is StateError
              ? error.message.toString()
              : 'Unable to read your location. Check your phone settings and try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(providerRepositoryProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final nearLatitude = _nearbyEnabled ? user?.latitude : null;
    final nearLongitude = _nearbyEnabled ? user?.longitude : null;
    final stream = _query.trim().isNotEmpty
        ? repo.searchProviders(
            _query.trim(),
            nearLatitude: nearLatitude,
            nearLongitude: nearLongitude,
          )
        : repo.discoverProviders(
            providerType: _providerType,
            washingMethod: _washingMethod,
            ironingMethod: _ironingMethod,
            nearLatitude: nearLatitude,
            nearLongitude: nearLongitude,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: Text(_nearbyEnabled
                        ? 'Refresh my location'
                        : 'Use my exact location'),
                  ),
                ),
                if (_nearbyEnabled)
                  IconButton(
                    tooltip: 'Show all locations',
                    onPressed: () => setState(() => _nearbyEnabled = false),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: MediaQuery.textScalerOf(context)
                .scale(48)
                .clamp(48.0, 96.0)
                .toDouble(),
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
                  onTap: () => setState(
                      () => _providerType = ProviderType.formalLaundry),
                ),
                _FilterChip(
                  label: ProviderType.mamaFua.label,
                  selected: _providerType == ProviderType.mamaFua,
                  onTap: () =>
                      setState(() => _providerType = ProviderType.mamaFua),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: WashingMethod.machineWashing.label,
                  selected: _washingMethod == WashingMethod.machineWashing,
                  onTap: () => setState(() => _washingMethod =
                      _washingMethod == WashingMethod.machineWashing
                          ? null
                          : WashingMethod.machineWashing),
                ),
                _FilterChip(
                  label: WashingMethod.manualHandWashing.label,
                  selected: _washingMethod == WashingMethod.manualHandWashing,
                  onTap: () => setState(() => _washingMethod =
                      _washingMethod == WashingMethod.manualHandWashing
                          ? null
                          : WashingMethod.manualHandWashing),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<ProviderModel>>(
              key: ValueKey(_retryVersion),
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ErrorStateView(
                    message: snapshot.error!,
                    onRetry: () => setState(() => _retryVersion++),
                  );
                }
                final providers = snapshot.data ?? [];
                if (providers.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No Providers Found',
                    message: 'Try a different filter or search term.',
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context);
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth < 360 ? 1 : 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: (textScale.scale(200) + 40)
                            .clamp(240.0, 440.0)
                            .toDouble(),
                      ),
                      itemCount: providers.length,
                      itemBuilder: (context, i) =>
                          ProviderCard(provider: providers[i]),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
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
        labelStyle: AppTextStyles.bodySmall(
            color: selected ? AppColors.white : AppColors.textMuted),
      ),
    );
  }
}
