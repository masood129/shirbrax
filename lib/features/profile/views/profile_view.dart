import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/app/routes/app_routes.dart';
import 'package:shirbrax/data/models/user_model.dart';
import 'package:shirbrax/data/models/post_model.dart';
import 'package:shirbrax/data/repositories/user_repository.dart';
import 'package:shirbrax/features/auth/controllers/auth_controller.dart';
import 'package:shirbrax/shared/widgets/media_card.dart';

class ProfileView extends StatefulWidget {
  final String userId;
  const ProfileView({super.key, required this.userId});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _userRepo = UserRepository();
  UserModel? _user;
  List<PostModel> _posts = [];
  bool _isLoading = true;
  bool _isSubscribing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final auth = Get.find<AuthController>();
    final isOwn = auth.user?.id == widget.userId;

    try {
      final user = await _userRepo.getUser(widget.userId);
      // A private account returns 403 for its post list — that is expected,
      // not an error, so keep the profile and show the locked state instead.
      final posts = user.canViewPosts
          ? await _userRepo.getUserPosts(widget.userId)
          : <PostModel>[];
      if (mounted) {
        setState(() {
          _user = user;
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _user = isOwn ? auth.user ?? UserModel.mockUser : UserModel.mockUser;
          _posts = PostModel.mockFeed.where((p) => p.author.id == widget.userId || isOwn).toList();
          _isLoading = false;
        });
      }
    }
  }

  /// Follow / unfollow, or send / withdraw a request on a private account.
  /// The server decides which — we mirror its returned status rather than
  /// guessing, so a private account correctly lands on 'pending'.
  Future<void> _toggleFollow() async {
    final user = _user;
    if (user == null) return;

    final previous = user;
    // Optimistic: a private account goes to pending, a public one to accepted.
    final nextStatus = switch (user.followStatus) {
      FollowStatus.none =>
        user.isPrivate ? FollowStatus.pending : FollowStatus.accepted,
      _ => FollowStatus.none,
    };
    final gainsFollower = nextStatus == FollowStatus.accepted;
    final losesFollower = previous.followStatus == FollowStatus.accepted;

    setState(() {
      _user = user.copyWith(
        followStatus: nextStatus,
        isFollowing: nextStatus == FollowStatus.accepted,
        followersCount: user.followersCount +
            (gainsFollower ? 1 : 0) -
            (losesFollower ? 1 : 0),
      );
    });

    try {
      final result = await _userRepo.followUser(user.id);
      if (!mounted) return;
      final serverStatus =
          UserModel.followStatusFromJson(result['follow_status']);
      setState(() {
        _user = _user!.copyWith(
          followStatus: serverStatus,
          isFollowing: serverStatus == FollowStatus.accepted,
          followersCount:
              result['followers_count'] as int? ?? _user!.followersCount,
        );
      });
      // Gaining or losing access changes what the grid may show.
      await _loadProfile();
    } catch (_) {
      if (mounted) setState(() => _user = previous);
    }
  }

  /// Simulated purchase — the backend records a fake payment reference.
  Future<void> _subscribe() async {
    final user = _user;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('خرید اشتراک'),
        content: Text(
          'اشتراک یک‌ماهه ${user.name} به مبلغ ${user.subscriptionPrice} تومان.\n\n'
          'توجه: پرداخت در این نسخه شبیه‌سازی شده است و مبلغی از شما دریافت نمی‌شود.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('پرداخت و فعال‌سازی'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubscribing = true);
    try {
      await _userRepo.subscribe(user.id);
      if (!mounted) return;
      Get.snackbar('اشتراک فعال شد', 'اکنون به پست‌های ویژه دسترسی دارید.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white);
      await _loadProfile();
    } catch (_) {
      // ApiClient already surfaced the error to the user.
    } finally {
      if (mounted) setState(() => _isSubscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isOwn = auth.user?.id == widget.userId;

    if (_isLoading || _user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _user!;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: CustomScrollView(
          slivers: [
            // ─── SliverAppBar with cover ───────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                  ),
                ),
              ),
              actions: isOwn
                  ? [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white),
                        onPressed: () => context.go(AppRoutes.settings),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.white),
                        onPressed: auth.logout,
                      ),
                    ]
                  : null,
            ),

            // ─── Profile info ─────────────────────────────
            SliverToBoxAdapter(
              child: _ProfileHeader(
                user: user,
                isOwn: isOwn,
                isSubscribing: _isSubscribing,
                onFollowToggle: _toggleFollow,
                onSubscribe: _subscribe,
              ),
            ),

            // ─── Divider ──────────────────────────────────
            const SliverToBoxAdapter(
              child: Divider(height: 1),
            ),

            // ─── Posts grid ───────────────────────────────
            // A private account we may not view shows a locked notice rather
            // than an "empty" one — the posts exist, they are just not for us.
            if (!user.canViewPosts)
              SliverFillRemaining(
                child: _PrivateAccountNotice(
                  isPending: user.isFollowPending,
                  onRequest: onFollowRequestTap(user),
                ),
              )
            else if (_posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    isOwn ? 'هنوز پستی ندارید' : 'این کاربر پستی ندارد',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.mutedForeground),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => MediaCard(
                      post: _posts[i],
                      compact: true,
                      onLockAction:
                          _posts[i].needsSubscription ? _subscribe : null,
                    ),
                    childCount: _posts.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Hide the request button once a request is already pending.
  VoidCallback? onFollowRequestTap(UserModel user) =>
      user.isFollowPending ? null : _toggleFollow;
}

/// Shown in place of the grid when the viewer may not browse a private account.
class _PrivateAccountNotice extends StatelessWidget {
  final bool isPending;
  final VoidCallback? onRequest;

  const _PrivateAccountNotice({required this.isPending, this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person_rounded,
                size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('این حساب خصوصی است',
                style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'درخواست شما فرستاده شد و در انتظار تأیید است.'
                  : 'برای دیدن پست‌ها و استوری‌ها درخواست دنبال کردن بفرستید.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.mutedForeground),
            ),
            if (onRequest != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('ارسال درخواست'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isOwn;
  final bool isSubscribing;
  final VoidCallback onFollowToggle;
  final VoidCallback onSubscribe;

  const _ProfileHeader({
    required this.user,
    required this.isOwn,
    required this.isSubscribing,
    required this.onFollowToggle,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Avatar
          Transform.translate(
            offset: const Offset(0, -40),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primaryContainer,
              backgroundImage: user.avatar != null
                  ? CachedNetworkImageProvider(user.avatar!)
                  : null,
              child: user.avatar == null
                  ? Text(
                      user.name.isNotEmpty ? user.name.substring(0, 1) : 'U',
                      style: AppTextStyles.displaySmall
                          .copyWith(color: AppColors.primary),
                    )
                  : null,
            ).animate().scale(delay: 100.ms),
          ),

          Transform.translate(
            offset: const Offset(0, -24),
            child: Column(
              children: [
                // Name
                Text(user.name, style: AppTextStyles.headlineSmall),
                const SizedBox(height: 2),
                Text('@${user.username}',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.mutedForeground)),

                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(user.bio!,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center),
                ],

                const SizedBox(height: 16),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                        label: 'پست', value: '${user.postsCount}'),
                    _StatDivider(),
                    _StatItem(
                        label: 'دنبال‌کننده',
                        value: '${user.followersCount}'),
                    _StatDivider(),
                    _StatItem(
                        label: 'دنبال‌شونده',
                        value: '${user.followingCount}'),
                  ],
                ),

                // Private-account marker
                if (user.isPrivate && !isOwn) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded,
                          size: 14, color: AppColors.mutedForeground),
                      const SizedBox(width: 4),
                      Text('حساب خصوصی',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.mutedForeground)),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Action button
                isOwn
                    ? OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.editProfile),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('ویرایش پروفایل'),
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _followButton()),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 16),
                                label: const Text('پیام'),
                              ),
                            ],
                          ),
                          // Paywall CTA — only for accounts actually selling one
                          if (user.subscriptionEnabled) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: user.isSubscribed
                                  ? OutlinedButton.icon(
                                      onPressed: null,
                                      icon: const Icon(
                                          Icons.verified_rounded,
                                          size: 16),
                                      label: Text(
                                        'مشترک هستید'
                                        '${user.subscriptionExpiresAt != null ? ' — تا ${_formatDate(user.subscriptionExpiresAt!)}' : ''}',
                                      ),
                                    )
                                  : FilledButton.icon(
                                      onPressed:
                                          isSubscribing ? null : onSubscribe,
                                      style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.warning),
                                      icon: isSubscribing
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white),
                                            )
                                          : const Icon(
                                              Icons
                                                  .workspace_premium_rounded,
                                              size: 16),
                                      label: Text(
                                          'اشتراک ماهانه — ${user.subscriptionPrice} تومان'),
                                    ),
                            ),
                          ],
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Follow button label/icon depends on the three-state follow status —
  /// a pending request must not read as "already following".
  Widget _followButton() {
    final (label, icon) = switch (user.followStatus) {
      FollowStatus.accepted => ('دنبال شده', Icons.person_remove_outlined),
      FollowStatus.pending => ('در انتظار تأیید', Icons.hourglass_top_rounded),
      FollowStatus.none => (
          user.isPrivate ? 'ارسال درخواست' : 'دنبال کردن',
          Icons.person_add_outlined,
        ),
    };

    final isPending = user.followStatus == FollowStatus.pending;

    return isPending
        ? OutlinedButton.icon(
            onPressed: onFollowToggle, // tapping again withdraws the request
            icon: Icon(icon, size: 16),
            label: Text(label),
          )
        : FilledButton.icon(
            onPressed: onFollowToggle,
            icon: Icon(icon, size: 16),
            label: Text(label),
          );
  }

  static String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.titleLarge
                .copyWith(fontWeight: FontWeight.w700)),
        Text(label,
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.mutedForeground)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 32, width: 1, color: AppColors.border);
  }
}
