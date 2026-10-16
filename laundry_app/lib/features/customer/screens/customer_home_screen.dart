import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/provider_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../widgets/provider_card.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final providerRepo = ref.watch(providerRepositoryProvider);
    final orderRepo = ref.watch(orderRepositoryProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome Back', style: AppTextStyles.bodyMedium(color: AppColors.textMuted)),
                        Text(user?.name.split(' ').first ?? 'Guest', style: AppTextStyles.heading2()),
                        if (user?.location.isNotEmpty == true)
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: AppColors.primaryPink),
                              const SizedBox(width: 4),
                              Text(user!.location, style: AppTextStyles.bodySmall()),
                            ],
                          ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.surfaceAlt,
                    backgroundImage:
                        (user?.profileImage.isNotEmpty ?? false) ? NetworkImage(user!.profileImage) : null,
                    child: (user?.profileImage.isEmpty ?? true)
                        ? const Icon(Icons.person, color: AppColors.primaryPink)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => ref.read(customerTabIndexProvider.notifier).state = 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.search, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Text('Search providers or services', style: AppTextStyles.bodyMedium(color: AppColors.textMuted)),
                  ]),
                ),
              ),
            ),
          ),
          // Active order banner
          SliverToBoxAdapter(
            child: StreamBuilder(
              stream: user == null ? null : orderRepo.watchCustomerOrders(user.uid),
              builder: (context, snapshot) {
                final orders = snapshot.data ?? [];
                final active = orders.where((o) =>
                    o.orderStatus != OrderStatus.completed && o.orderStatus != OrderStatus.cancelled);
                if (active.isEmpty) return const SizedBox.shrink();
                final order = active.first;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: GestureDetector(
                    onTap: () => context.push('${AppRoutes.customerHome}/order/${order.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.pinkGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping_rounded, color: AppColors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Active Order With ${order.providerName}',
                                    style: AppTextStyles.bodyMedium(color: AppColors.white)),
                                Text(order.orderStatus.label,
                                    style: AppTextStyles.caption(color: AppColors.white)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.white),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Mama Fua Providers',
              actionLabel: 'See All',
              onAction: () => ref.read(customerTabIndexProvider.notifier).state = 1,
            ),
          ),
          SliverToBoxAdapter(
            child: _ProviderRow(
              stream: providerRepo.discoverProviders(providerType: ProviderType.mamaFua),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Formal Laundry Providers',
              actionLabel: 'See All',
              onAction: () => ref.read(customerTabIndexProvider.notifier).state = 1,
            ),
          ),
          SliverToBoxAdapter(
            child: _ProviderRow(
              stream: providerRepo.discoverProviders(providerType: ProviderType.formalLaundry),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({required this.stream});
  final Stream<List<ProviderModel>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProviderModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
        final providers = snapshot.data ?? [];
        if (providers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: EmptyStateView(icon: Icons.storefront_outlined, title: 'No Providers Found Yet'),
          );
        }
        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: providers.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(width: 190, child: ProviderCard(provider: providers[i])),
            ),
          ),
        );
      },
    );
  }
}
