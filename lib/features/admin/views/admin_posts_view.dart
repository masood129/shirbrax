import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/core/network/media_headers.dart';
import 'package:shirbrax/data/models/post_model.dart';
import 'package:shirbrax/data/repositories/admin_repository.dart';
import 'package:shirbrax/shared/widgets/locked_media.dart';

class AdminPostsView extends StatefulWidget {
  const AdminPostsView({super.key});

  @override
  State<AdminPostsView> createState() => _AdminPostsViewState();
}

class _AdminPostsViewState extends State<AdminPostsView> {
  final _adminRepo = AdminRepository();
  String _filter = 'all'; // all | photo | video
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _adminRepo.getPosts(mediaType: _filter);
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _posts = PostModel.mockFeed;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePost(PostModel post) async {
    setState(() {
      _posts.remove(post);
    });

    try {
      await _adminRepo.deletePost(post.id);
    } catch (_) {}
  }

  void _onFilterSelected(String filter) {
    setState(() => _filter = filter);
    _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت پست‌ها'),
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'همه',
                  selected: _filter == 'all',
                  onTap: () => _onFilterSelected('all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'عکس',
                  selected: _filter == 'photo',
                  onTap: () => _onFilterSelected('photo'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'ویدیو',
                  selected: _filter == 'video',
                  onTap: () => _onFilterSelected('video'),
                ),
                const Spacer(),
                Text('${_posts.length} پست',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.mutedForeground)),
              ],
            ),
          ),

          // Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadPosts,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 4 : 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _posts.length,
                      itemBuilder: (ctx, i) => _PostThumb(
                        post: _posts[i],
                        onDelete: () {
                          showDialog(
                            context: ctx,
                            builder: (_) => AlertDialog(
                              title: const Text('حذف پست'),
                              content: const Text(
                                  'آیا مطمئن هستید که می‌خواهید این پست را حذف کنید؟'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('انصراف'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _deletePost(_posts[i]);
                                  },
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.error),
                                  child: const Text('حذف'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PostThumb extends StatelessWidget {
  final PostModel post;
  final VoidCallback onDelete;
  const _PostThumb({required this.post, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onDelete,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (post.isLocked)
              LockedMediaPlaceholder(reason: post.lockReason, compact: true)
            else
              CachedNetworkImage(
                imageUrl: post.displayUrl!,
                httpHeaders: MediaHeaders.authHeaders(),
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    Container(color: AppColors.muted),
              ),
            if (post.isVideo)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.videocam_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_rounded,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 2),
                    Text('${post.likesCount}',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.muted,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
              color: selected ? Colors.white : AppColors.mutedForeground),
        ),
      ),
    );
  }
}
