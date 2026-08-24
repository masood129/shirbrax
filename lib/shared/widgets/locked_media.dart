import 'package:flutter/material.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/data/models/post_model.dart';

/// Copy shown for each reason the server withheld a post's media.
class LockCopy {
  final String title;
  final String? action;
  final IconData icon;

  const LockCopy({required this.title, this.action, required this.icon});

  factory LockCopy.forReason(LockReason? reason) {
    switch (reason) {
      case LockReason.subscribersOnly:
        return const LockCopy(
          title: 'این پست فقط برای مشترکین است',
          action: 'خرید اشتراک',
          icon: Icons.workspace_premium_rounded,
        );
      case LockReason.followersOnly:
        return const LockCopy(
          title: 'این پست فقط برای دنبال‌کنندگان است',
          action: 'دنبال کردن',
          icon: Icons.lock_outline_rounded,
        );
      case LockReason.privateAccount:
        return const LockCopy(
          title: 'این حساب خصوصی است',
          action: 'ارسال درخواست',
          icon: Icons.lock_person_rounded,
        );
      case null:
        return const LockCopy(
          title: 'این محتوا قابل نمایش نیست',
          icon: Icons.visibility_off_rounded,
        );
    }
  }
}

/// Placeholder drawn in place of media the viewer may not open.
///
/// Renders no image at all rather than blurring one — a locked post carries no
/// media URL from the server, so there is nothing to leak here.
class LockedMediaPlaceholder extends StatelessWidget {
  final LockReason? reason;

  /// Compact form for grid cells; hides the label and button.
  final bool compact;

  /// Tapping the call to action — subscribe, follow, or request. When null the
  /// button is hidden (e.g. the viewer already has a request pending).
  final VoidCallback? onAction;

  const LockedMediaPlaceholder({
    super.key,
    required this.reason,
    this.compact = false,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final copy = LockCopy.forReason(reason);
    final isPaid = reason == LockReason.subscribersOnly;
    final accent = isPaid ? AppColors.warning : AppColors.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.12),
            AppColors.surfaceVariant.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 16 : 40, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(copy.icon, size: compact ? 28 : 44, color: accent),
            if (!compact) ...[
              const SizedBox(height: 12),
              Text(
                copy.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (copy.action != null && onAction != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(copy.icon, size: 18),
                  label: Text(copy.action!),
                  style: FilledButton.styleFrom(backgroundColor: accent),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Small corner badge marking a post's audience. Hidden for public posts.
class VisibilityBadge extends StatelessWidget {
  final PostVisibility visibility;

  const VisibilityBadge({super.key, required this.visibility});

  @override
  Widget build(BuildContext context) {
    if (visibility == PostVisibility.public) return const SizedBox.shrink();

    final isPaid = visibility == PostVisibility.subscribers;
    final color = isPaid ? AppColors.warning : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.workspace_premium_rounded : Icons.people_alt_rounded,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isPaid ? 'مشترکین' : 'دنبال‌کنندگان',
            style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
