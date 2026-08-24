import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/app/routes/app_routes.dart';
import 'package:shirbrax/data/models/notif_model.dart';
import 'package:shirbrax/data/repositories/notif_repository.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final _notifRepo = NotifRepository();
  List<NotifModel> _notifs = [];
  bool _isLoading = true;

  int get _unreadCount => _notifs.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fa', timeago.FaMessages());
    _loadNotifs();
  }

  Future<void> _loadNotifs() async {
    setState(() => _isLoading = true);
    try {
      final notifs = await _notifRepo.getNotifications();
      if (mounted) {
        setState(() {
          _notifs = notifs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _notifs = NotifModel.mockList;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _notifs = _notifs.map((n) => n.copyWith(isRead: true)).toList());
    try {
      await _notifRepo.markAllRead();
    } catch (_) {}
  }

  Future<void> _onNotifTapped(NotifModel notif, int index) async {
    setState(() {
      _notifs[index] = notif.copyWith(isRead: true);
    });
    try {
      await _notifRepo.markRead(notif.id);
    } catch (_) {}

    if (notif.postId != null && mounted) {
      context.go(AppRoutes.mediaPath(notif.postId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اعلان‌ها'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('همه را خواندم',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.primary)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifs.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadNotifs,
                  child: ListView.separated(
                    itemCount: _notifs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                    itemBuilder: (ctx, i) => _NotifTile(
                      notif: _notifs[i],
                      onTap: () => _onNotifTapped(_notifs[i], i),
                    ).animate().fadeIn(delay: (i * 40).ms),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none_rounded,
              size: 80, color: AppColors.mutedForeground),
          const SizedBox(height: 16),
          Text('اعلانی ندارید',
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.mutedForeground)),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotifModel notif;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notif.isRead
            ? Colors.transparent
            : AppColors.primary.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar + notif type icon
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage: notif.actorAvatar != null
                      ? CachedNetworkImageProvider(notif.actorAvatar!)
                      : null,
                  child: notif.actorAvatar == null
                      ? Text(notif.actorName.isNotEmpty ? notif.actorName[0] : 'U',
                          style: AppTextStyles.titleSmall
                              .copyWith(color: AppColors.primary))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _notifColor(notif.type),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).colorScheme.surface, width: 2),
                    ),
                    child: Icon(_notifIcon(notif.type),
                        size: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${notif.actorName} ',
                          style: AppTextStyles.titleSmall,
                        ),
                        TextSpan(
                          text: notif.message,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notif.createdAt, locale: 'fa'),
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
            ),
            // Post thumbnail
            if (notif.postThumbnail != null) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: notif.postThumbnail!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            // Unread dot
            if (!notif.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _notifIcon(NotifType type) {
    switch (type) {
      case NotifType.like:
        return Icons.favorite_rounded;
      case NotifType.comment:
        return Icons.chat_bubble_rounded;
      case NotifType.follow:
        return Icons.person_add_rounded;
      case NotifType.mention:
        return Icons.alternate_email_rounded;
      case NotifType.followRequest:
        return Icons.person_add_alt_1_rounded;
      case NotifType.followAccepted:
        return Icons.how_to_reg_rounded;
      case NotifType.subscription:
        return Icons.workspace_premium_rounded;
    }
  }

  Color _notifColor(NotifType type) {
    switch (type) {
      case NotifType.like:
        return AppColors.primary;
      case NotifType.comment:
        return AppColors.accent;
      case NotifType.follow:
        return AppColors.secondary;
      case NotifType.mention:
        return AppColors.warning;
      case NotifType.followRequest:
        return AppColors.info;
      case NotifType.followAccepted:
        return AppColors.success;
      case NotifType.subscription:
        return AppColors.warning;
    }
  }
}
