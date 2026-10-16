import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/provider_model.dart';
import '../../../core/models/review_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class ProviderDetailsScreen extends ConsumerWidget {
  const ProviderDetailsScreen({super.key, required this.providerId});
  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerRepo = ref.watch(providerRepositoryProvider);
    final reviewRepo = ref.watch(reviewRepositoryProvider);

    return Scaffold(
      body: StreamBuilder<ProviderModel?>(
        stream: providerRepo.watchProvider(providerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final provider = snapshot.data;
          if (provider == null) {
            return const ErrorStateView(message: 'This provider is no longer available.');
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(gradient: AppColors.pinkGradient),
                    child: provider.profileImage.isNotEmpty
                        ? Image.network(provider.profileImage, fit: BoxFit.cover)
                        : const Center(
                            child: Icon(Icons.local_laundry_service_rounded, size: 64, color: AppColors.white)),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(provider.providerName, style: AppTextStyles.heading2())),
                          if (provider.isVerified)
                            const Icon(Icons.verified_rounded, color: AppColors.primaryPink),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        ProviderTypeBadge(type: provider.providerType),
                        _InfoChip(icon: Icons.star_rounded, label: '${provider.rating.toStringAsFixed(1)} (${provider.reviewCount})'),
                        _InfoChip(icon: Icons.timer_outlined, label: '${provider.turnaroundHours}h turnaround'),
                        _InfoChip(
                          icon: provider.isAvailable ? Icons.check_circle : Icons.pause_circle,
                          label: provider.isAvailable ? 'Available Now' : 'Currently Unavailable',
                        ),
                      ]),
                      const SizedBox(height: 16),
                      Text(provider.description.isNotEmpty
                          ? provider.description
                          : 'This provider has not added a description yet.'),
                      const SizedBox(height: 16),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primaryPink),
                        const SizedBox(width: 6),
                        Expanded(child: Text(provider.location)),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.local_laundry_service_outlined, size: 18, color: AppColors.primaryPink),
                        const SizedBox(width: 6),
                        Text(provider.washingMethod.label),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.iron_outlined, size: 18, color: AppColors.primaryPink),
                        const SizedBox(width: 6),
                        Text(provider.ironingMethod.label),
                      ]),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SectionHeader(title: 'Services'),
              ),
              SliverToBoxAdapter(
                child: StreamBuilder(
                  stream: providerRepo.watchServices(providerId),
                  builder: (context, snapshot) {
                    final services = snapshot.data ?? [];
                    if (services.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: EmptyStateView(icon: Icons.list_alt, title: 'No Services Available'),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: services
                            .map((s) => Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    title: Text(s.name, style: AppTextStyles.bodyLarge()),
                                    subtitle: Text(s.description),
                                    trailing: Text('KES ${s.price.toStringAsFixed(0)} / ${s.pricingUnit}',
                                        style: AppTextStyles.bodyMedium(color: AppColors.primaryPink)),
                                  ),
                                ))
                            .toList(),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(child: SectionHeader(title: 'Reviews')),
              SliverToBoxAdapter(
                child: StreamBuilder<List<ReviewModel>>(
                  stream: reviewRepo.watchForProvider(providerId),
                  builder: (context, snapshot) {
                    final reviews = snapshot.data ?? [];
                    if (reviews.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: EmptyStateView(icon: Icons.star_border, title: 'No Reviews Yet'),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: reviews
                            .take(5)
                            .map((r) => Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    title: Row(children: [
                                      Text(r.customerName, style: AppTextStyles.bodyMedium()),
                                      const Spacer(),
                                      ...List.generate(
                                          5,
                                          (i) => Icon(
                                                i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                                size: 16,
                                                color: AppColors.primaryPink,
                                              )),
                                    ]),
                                    subtitle: r.comment.isNotEmpty ? Text(r.comment) : null,
                                  ),
                                ))
                            .toList(),
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PremiumButton(
            label: 'Book Service',
            onPressed: () => context.push('${AppRoutes.customerHome}/booking/$providerId'),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.primaryPink),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodySmall()),
      ]),
    );
  }
}
