import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/app/routes/app_routes.dart';
import 'package:shirbrax/core/utils/responsive_helper.dart';
import 'package:shirbrax/features/auth/controllers/auth_controller.dart';
import 'package:shirbrax/features/story/widgets/story_bar.dart';
import 'package:shirbrax/shared/controllers/theme_controller.dart';
import 'package:shirbrax/shared/widgets/loading_indicator.dart';
import 'package:shirbrax/shared/widgets/media_card.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(HomeController());
    final auth = Get.find<AuthController>();
    final theme = Get.find<ThemeController>();
    final width = MediaQuery.sizeOf(context).width;
    final cols = ResponsiveHelper.feedColumns(width);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.photo_library_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text('شیربرکس',
                style: AppTextStyles.titleLarge
                    .copyWith(color: AppColors.primary)),
          ],
        ),
        actions: [
          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.go(AppRoutes.notifications),
          ),
          // Dark mode
          Obx(() => IconButton(
                icon: Icon(theme.isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded),
                onPressed: theme.toggle,
              )),
          // Avatar
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => context
                      .go(AppRoutes.profilePath(auth.user?.id ?? '1')),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      auth.user?.name.substring(0, 1) ?? 'U',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
              )),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading) return const FeedShimmer();

        if (ctrl.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_library_outlined,
                    size: 64, color: AppColors.mutedForeground),
                const SizedBox(height: 16),
                Text('هنوز پستی نیست',
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.mutedForeground)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: ctrl.refresh,
          child: cols == 1
              ? _buildSingleColumnFeed(ctrl)
              : _buildGridFeed(ctrl, cols),
        );
      }),
    );
  }

  Widget _buildSingleColumnFeed(HomeController ctrl) {
    return CustomScrollView(
      slivers: [
        // Stories
        const SliverToBoxAdapter(child: StoryBar()),
        const SliverToBoxAdapter(
          child: Divider(height: 1),
        ),
        // Feed posts
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              if (i == ctrl.posts.length) {
                if (ctrl.hasMore) ctrl.loadMore();
                return ctrl.hasMore
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      )
                    : const SizedBox(height: 80);
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                child: MediaCard(
                  post: ctrl.posts[i],
                  onLike: () => ctrl.toggleLike(ctrl.posts[i].id),
                  // Unlocking happens on the author's profile, where the
                  // follow / subscribe actions live.
                  onLockAction: () => context
                      .go(AppRoutes.profilePath(ctrl.posts[i].author.id)),
                ),
              );
            },
            childCount: ctrl.posts.length + 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGridFeed(HomeController ctrl, int cols) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: StoryBar()),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) => MediaCard(
                post: ctrl.posts[i],
                compact: true,
                onLike: () => ctrl.toggleLike(ctrl.posts[i].id),
                onLockAction: () => context
                    .go(AppRoutes.profilePath(ctrl.posts[i].author.id)),
              ),
              childCount: ctrl.posts.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
          ),
        ),
      ],
    );
  }
}
