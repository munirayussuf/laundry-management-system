import 'package:flutter/material.dart';
import '../constants/app_enums.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A primary call to action button with a built in loading state so it can
/// never be pressed twice while a request is in flight.
class PremiumButton extends StatelessWidget {
  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onPressed == null;
    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: outlined ? AppColors.primaryPink : AppColors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: outlined ? AppColors.primaryPink : AppColors.white),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    if (outlined) {
      return OutlinedButton(onPressed: disabled ? null : onPressed, child: child);
    }
    return ElevatedButton(onPressed: disabled ? null : onPressed, child: child);
  }
}

/// Confirmation dialog used before every destructive action in the app.
/// Returns true only when the user explicitly confirms deletion.
Future<bool> showDeleteConfirmationDialog(
  BuildContext context, {
  String title = 'Delete this item',
  String message = 'Are you sure you want to delete this item? This action cannot be undone.',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message, style: AppTextStyles.bodyMedium()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
    ),
  );
}

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        const Icon(Icons.error, color: AppColors.error, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
    ),
  );
}

/// Full screen or inline empty state with an optional call to action.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.rose),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.heading3(), textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, style: AppTextStyles.bodyMedium(color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            PremiumButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.wifi_off_rounded,
      title: 'Something went wrong',
      message: message,
      actionLabel: onRetry != null ? 'Try Again' : null,
      onAction: onRetry,
    );
  }
}

/// Distinct but consistent badge for Formal Laundry versus Mama Fua / Jua
/// Kali providers, as required by the provider discovery experience.
class ProviderTypeBadge extends StatelessWidget {
  const ProviderTypeBadge({super.key, required this.type, this.compact = false});
  final ProviderType type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isMamaFua = type == ProviderType.mamaFua;
    final color = isMamaFua ? AppColors.mamaFuaBadge : AppColors.formalBadge;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isMamaFua ? Icons.handshake_rounded : Icons.local_laundry_service_rounded,
              size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(type.label, style: AppTextStyles.caption(color: color)),
        ],
      ),
    );
  }
}

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});
  final OrderStatus status;

  Color get _color {
    switch (status) {
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.pending:
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label, style: AppTextStyles.caption(color: _color)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.heading3()),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// The rounded gradient header used at the top of the product screens. It
/// carries a title, an optional subtitle, a back control and optional
/// trailing actions, all in white against the pink gradient.
class PinkAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PinkAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.actions,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 92 : 112);

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.pinkGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: AppColors.pinkGlow, blurRadius: 18, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            if (canPop)
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.white, size: 20),
                ),
              )
            else if (leadingIcon != null)
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(leadingIcon, color: AppColors.white, size: 20),
              ),
            if (canPop || leadingIcon != null) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading3(color: AppColors.white),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(color: AppColors.white.withOpacity(0.85)),
                    ),
                ],
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}

/// The soft pink circle that sits to the left of a row and holds an icon,
/// used throughout the card layouts.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.size = 46, this.color});

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(color: AppColors.softPink, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.5, color: color ?? AppColors.primaryPink),
    );
  }
}

/// A white card with the standard hairline pink border and rounded corners.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap, this.tinted = false});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  /// Tinted cards use the pale blush fill seen on informational panels.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tinted ? AppColors.paleBlush : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      ),
    );
  }
}
