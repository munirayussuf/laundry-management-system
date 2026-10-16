import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/provider_model.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class ProviderCard extends StatelessWidget {
  const ProviderCard({super.key, required this.provider});
  final ProviderModel provider;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.customerHome}/provider/${provider.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppColors.pinkGradient),
              child: provider.profileImage.isNotEmpty
                  ? Image.network(provider.profileImage, fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.local_laundry_service_rounded, color: AppColors.white, size: 32)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.providerName,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyLarge()),
                  const SizedBox(height: 4),
                  ProviderTypeBadge(type: provider.providerType, compact: true),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.primaryPink),
                      const SizedBox(width: 2),
                      Text(provider.rating.toStringAsFixed(1), style: AppTextStyles.bodySmall()),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(provider.location,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('From KES ${provider.startingPrice.toStringAsFixed(0)}',
                      style: AppTextStyles.bodySmall(color: AppColors.primaryPink)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
