import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/app/routes/app_routes.dart';
import 'package:shirbrax/core/network/media_headers.dart';
import 'package:shirbrax/data/models/post_model.dart';
import 'package:shirbrax/features/home/controllers/home_controller.dart';
import 'package:shirbrax/shared/widgets/locked_media.dart';

/// Shared media card used in feed, profile, and admin views
class MediaCard extends StatelessWidget {
  final PostModel post;
  final bool compact;
  final VoidCallback? onTap;

  /// Tapping the unlock call to action on a locked post (subscribe / follow).
  /// When null the button is hidden.
  final VoidCallback? onLockAction;

  /// Like handler. Defaults to HomeController when it is registered.
  final VoidCallback? onLike;

  const MediaCard({
    super.key,
    required this.post,
    this.compact = false,
    this.onTap,
    this.onLockAction,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.go(AppRoutes.mediaPath(post.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Author header ───────────────────────────
            if (!compact) _buildHeader(context),

            // ─── Media thumbnail ─────────────────────────
            _buildMedia(context),

            // ─── Actions & caption ───────────────────────
            if (!compact) _buildFooter(context),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => context.go(AppRoutes.profilePath(post.author.id)),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryContainer,
              backgroundImage: post.author.avatar != null
                  ? CachedNetworkImageProvider(post.author.avatar!)
                  : null,
              child: post.author.avatar == null
                  ? Text(
                      post.author.name.substring(0, 1),
                      style: AppTextStyles.titleSmall
                          .copyWith(color: AppColors.primary),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.author.name, style: AppTextStyles.titleSmall),
                Text(
                  '@${post.author.username} · ${timeago.format(post.createdAt, locale: 'fa')}',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
          // More options
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, size: 20),
            color: AppColors.mutedForeground,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    // A locked post carries no media URL — render the paywall/lock instead of
    // attempting a network load that would 403.
    if (post.isLocked) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: LockedMediaPlaceholder(
          reason: post.lockReason,
          compact: compact,
          onAction: onLockAction,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          CachedNetworkImage(
            imageUrl: post.displayUrl!,
            httpHeaders: MediaHeaders.authHeaders(),
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: AppColors.muted),
            errorWidget: (_, _, _) => Container(
              color: AppColors.muted,
              child: const Icon(Icons.broken_image_outlined,
                  color: AppColors.mutedForeground),
            ),
          ),
          // Video overlay
          if (post.isVideo)
            Container(
              color: Colors.black.withValues(alpha: 0.2),
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          // Video duration badge
          if (post.isVideo && post.videoDuration != null)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatDuration(post.videoDuration!),
                  style:
                      AppTextStyles.labelSmall.copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action row
          Row(
            children: [
              _LikeButton(post: post, onLike: onLike),
              const SizedBox(width: 16),
              // Comment
              _ActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                count: post.commentsCount,
                onTap: () => context.go(AppRoutes.mediaPath(post.id)),
              ),
              const Spacer(),
              // Visibility badge — tells the author who can see this post
              VisibilityBadge(visibility: post.visibility),
              const SizedBox(width: 8),
              // Share
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 20),
                color: AppColors.mutedForeground,
                onPressed: () {},
              ),
            ],
          ),
          // Caption
          if (post.caption != null && post.caption!.isNotEmpty) ...[
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${post.author.username} ',
                    style: AppTextStyles.labelMedium,
                  ),
                  TextSpan(
                    text: post.caption,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.onSurface),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Tags
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: post.tags
                  .map((tag) => Text(
                        '#$tag',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.accent),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _LikeButton extends StatelessWidget {
  final PostModel post;

  /// Supplied by the host screen. Falls back to HomeController only when that
  /// controller is actually registered — this widget is also used from the
  /// profile and admin screens, where it is not.
  final VoidCallback? onLike;

  const _LikeButton({required this.post, this.onLike});

  void _handleTap() {
    if (onLike != null) {
      onLike!();
      return;
    }
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().toggleLike(post.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to like on a post whose media the viewer cannot open.
    final enabled = !post.isLocked;

    return GestureDetector(
      onTap: enabled ? _handleTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Row(
          children: [
            Icon(
              post.isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: post.isLiked ? AppColors.primary : AppColors.mutedForeground,
              size: 22,
            ),
            const SizedBox(width: 4),
            Text(
              '${post.likesCount}',
              style: AppTextStyles.labelMedium.copyWith(
                color:
                    post.isLiked ? AppColors.primary : AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.mutedForeground, size: 20),
          const SizedBox(width: 4),
          Text('$count', style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}
