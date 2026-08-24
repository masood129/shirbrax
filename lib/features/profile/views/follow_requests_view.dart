import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shirbrax/app/routes/app_routes.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/data/models/user_model.dart';
import 'package:shirbrax/features/profile/controllers/follow_requests_controller.dart';

/// Approve or reject people asking to follow a private account.
class FollowRequestsView extends StatelessWidget {
  const FollowRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<FollowRequestsController>();
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('درخواست‌های دنبال کردن')),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isWide ? 640 : double.infinity),
          child: Obx(() {
            if (ctrl.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (ctrl.requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox_outlined,
                        size: 64, color: AppColors.mutedForeground),
                    const SizedBox(height: 16),
                    Text('درخواستی در انتظار تأیید نیست',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.mutedForeground)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: ctrl.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: ctrl.requests.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final user = ctrl.requests[i];
                  return _RequestTile(
                    user: user,
                    isBusy: ctrl.isBusy(user.id),
                    onAccept: () => ctrl.respond(user.id, accept: true),
                    onReject: () => ctrl.respond(user.id, accept: false),
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final UserModel user;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestTile({
    required this.user,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.go(AppRoutes.profilePath(user.id)),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primaryContainer,
        backgroundImage: user.avatar != null
            ? CachedNetworkImageProvider(user.avatar!)
            : null,
        child: user.avatar == null
            ? Text(
                user.name.isNotEmpty ? user.name.substring(0, 1) : '؟',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.primary),
              )
            : null,
      ),
      title: Text(user.name, style: AppTextStyles.bodyMedium),
      subtitle: Text('@${user.username}', style: AppTextStyles.labelSmall),
      trailing: isBusy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 34),
                  ),
                  child: const Text('تأیید'),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 34),
                  ),
                  child: const Text('رد'),
                ),
              ],
            ),
    );
  }
}
