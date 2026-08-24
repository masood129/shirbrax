import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/app/routes/app_routes.dart';
import 'package:shirbrax/core/network/media_headers.dart';
import 'package:shirbrax/data/models/post_model.dart';
import 'package:shirbrax/data/models/comment_model.dart';
import 'package:shirbrax/data/models/user_model.dart';
import 'package:shirbrax/features/auth/controllers/auth_controller.dart';
import 'package:shirbrax/shared/widgets/locked_media.dart';

import 'package:shirbrax/data/repositories/post_repository.dart';

class MediaDetailView extends StatefulWidget {
  final String mediaId;
  const MediaDetailView({super.key, required this.mediaId});

  @override
  State<MediaDetailView> createState() => _MediaDetailViewState();
}

class _MediaDetailViewState extends State<MediaDetailView> {
  final _postRepo = PostRepository();
  PostModel? _post;
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  VideoPlayerController? _videoCtrl;
  bool _videoInitialized = false;
  bool _isPlaying = false;
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fa', timeago.FaMessages());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final post = await _postRepo.getPost(widget.mediaId);
      // Comments are gated with the post; a locked teaser has none to show.
      final comments = post.isLocked
          ? <CommentModel>[]
          : await _postRepo.getComments(widget.mediaId);
      if (mounted) {
        setState(() {
          _post = post;
          _comments = comments;
          _isLoading = false;
        });
        if (post.isVideo && !post.isLocked) _initVideo(post.mediaUrl!);
      }
    } catch (_) {
      // Fallback to mock
      final mock = PostModel.mockFeed.firstWhereOrNull((p) => p.id == widget.mediaId) ??
          PostModel.mockFeed.first;
      if (mounted) {
        setState(() {
          _post = mock;
          _comments = CommentModel.mockFor(mock.id);
          _isLoading = false;
        });
        if (mock.isVideo && mock.mediaUrl != null) _initVideo(mock.mediaUrl!);
      }
    }
  }

  Future<void> _initVideo(String url) async {
    _videoCtrl = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: MediaHeaders.authHeaders(),
    );
    await _videoCtrl!.initialize();
    if (mounted) setState(() => _videoInitialized = true);
  }

  /// Unlock CTA on the detail screen — routes to the author's profile, where
  /// the follow / subscribe actions live.
  void _handleUnlock() {
    final post = _post;
    if (post == null) return;
    context.go(AppRoutes.profilePath(post.author.id));
  }

  void _togglePlay() {
    if (_videoCtrl == null) return;
    setState(() {
      _isPlaying = !_isPlaying;
      _isPlaying ? _videoCtrl!.play() : _videoCtrl!.pause();
    });
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;
    final currentLiked = _post!.isLiked;
    final currentCount = _post!.likesCount;

    setState(() {
      _post = _post!.copyWith(
        isLiked: !currentLiked,
        likesCount: currentLiked ? currentCount - 1 : currentCount + 1,
      );
    });

    try {
      await _postRepo.likePost(_post!.id);
    } catch (_) {
      // Revert if failed
      if (mounted) {
        setState(() {
          _post = _post!.copyWith(isLiked: currentLiked, likesCount: currentCount);
        });
      }
    }
  }

  Future<void> _sendComment() async {
    if (_commentCtrl.text.trim().isEmpty || _post == null) return;
    final text = _commentCtrl.text.trim();
    setState(() => _submitting = true);

    try {
      final newComment = await _postRepo.addComment(_post!.id, text);
      if (mounted) {
        setState(() {
          _comments.insert(0, newComment);
          _post = _post!.copyWith(commentsCount: _post!.commentsCount + 1);
        });
      }
    } catch (_) {
      final auth = Get.find<AuthController>();
      final fallbackComment = CommentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        postId: _post!.id,
        author: auth.user ?? UserModel.mockUser,
        text: text,
        createdAt: DateTime.now(),
      );
      if (mounted) {
        setState(() {
          _comments.insert(0, fallbackComment);
          _post = _post!.copyWith(commentsCount: _post!.commentsCount + 1);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
        _commentCtrl.clear();
        FocusScope.of(context).unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('در حال بارگذاری...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final post = _post!;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(post.author.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: isWide ? _buildWideLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMedia(),
                _buildPostInfo(),
                const Divider(height: 1),
                _buildCommentsList(),
              ],
            ),
          ),
        ),
        _buildCommentInput(),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left: Media
        Expanded(
          flex: 6,
          child: Container(
            color: Colors.black,
            child: _buildMedia(fullScreen: true),
          ),
        ),
        // Right: Info + Comments
        Container(
          width: 380,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.border),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPostInfo(),
                      const Divider(height: 1),
                      _buildCommentsList(),
                    ],
                  ),
                ),
              ),
              _buildCommentInput(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedia({bool fullScreen = false}) {
    // Locked post — show the paywall/lock instead of any media attempt.
    if (_post!.isLocked) {
      return AspectRatio(
        aspectRatio: fullScreen ? 16 / 9 : 4 / 3,
        child: LockedMediaPlaceholder(
          reason: _post!.lockReason,
          onAction: _handleUnlock,
        ),
      );
    }

    if (_post!.isVideo) {
      return AspectRatio(
        aspectRatio: fullScreen ? 16 / 9 : 4 / 3,
        child: GestureDetector(
          onTap: _togglePlay,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _videoInitialized && _videoCtrl != null
                  ? VideoPlayer(_videoCtrl!)
                  : CachedNetworkImage(
                      imageUrl: _post!.thumbnailUrl ?? '',
                      fit: BoxFit.cover,
                    ),
              if (!_isPlaying)
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 38),
                  ),
                ),
              // Video progress
              if (_videoInitialized && _videoCtrl != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(
                    _videoCtrl!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: AppColors.primary,
                      bufferedColor: AppColors.primary.withValues(alpha: 0.3),
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Photo
    return GestureDetector(
      onTap: () => _showPhotoViewer(context),
      child: CachedNetworkImage(
        imageUrl: _post!.mediaUrl!,
        httpHeaders: MediaHeaders.authHeaders(),
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, _) => AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(color: AppColors.muted),
        ),
      ),
    );
  }

  void _showPhotoViewer(BuildContext context) {
    if (_post!.isLocked || _post!.mediaUrl == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, _, _) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
          body: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: _post!.mediaUrl!,
              httpHeaders: MediaHeaders.authHeaders(),
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          GestureDetector(
            onTap: () => context.go(AppRoutes.profilePath(_post!.author.id)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage: _post!.author.avatar != null
                      ? CachedNetworkImageProvider(_post!.author.avatar!)
                      : null,
                  child: _post!.author.avatar == null
                      ? Text(_post!.author.name[0],
                          style: AppTextStyles.titleSmall
                              .copyWith(color: AppColors.primary))
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_post!.author.name, style: AppTextStyles.titleSmall),
                    Text(
                      timeago.format(_post!.createdAt, locale: 'fa'),
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Caption
          if (_post!.caption != null)
            Text(_post!.caption!, style: AppTextStyles.bodyMedium),
          // Tags
          if (_post!.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _post!.tags
                  .map((t) => GestureDetector(
                        onTap: () {},
                        child: Text('#$t',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.accent)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          // Actions
          Row(
            children: [
              _LikeButton(
                isLiked: _post!.isLiked,
                count: _post!.likesCount,
                onTap: _toggleLike,
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 22, color: AppColors.mutedForeground),
                  const SizedBox(width: 4),
                  Text('${_post!.commentsCount}',
                      style: AppTextStyles.labelMedium),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.bookmark_border_rounded),
                onPressed: () {},
                color: AppColors.mutedForeground,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text('اولین نظر را بنویسید!',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.mutedForeground)),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _comments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) =>
          _CommentTile(comment: _comments[i]).animate().fadeIn(delay: (i * 50).ms),
    );
  }

  Widget _buildCommentInput() {
    final auth = Get.find<AuthController>();
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: auth.user?.avatar != null
                ? CachedNetworkImageProvider(auth.user!.avatar!)
                : null,
            child: auth.user?.avatar == null
                ? Text(auth.user?.name[0] ?? 'U',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.primary))
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _commentCtrl,
              decoration: InputDecoration(
                hintText: 'نظر بنویسید...',
                hintStyle: AppTextStyles.bodySmall,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                isDense: true,
              ),
              maxLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(),
            ),
          ),
          const SizedBox(width: 8),
          _submitting
              ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                )
              : IconButton(
                  onPressed: _sendComment,
                  icon: const Icon(Icons.send_rounded),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                  ),
                ),
        ],
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  final bool isLiked;
  final int count;
  final VoidCallback onTap;
  const _LikeButton(
      {required this.isLiked, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(isLiked),
              color: isLiked ? AppColors.primary : AppColors.mutedForeground,
              size: 24,
            ),
          ),
          const SizedBox(width: 4),
          Text('$count',
              style: AppTextStyles.labelMedium.copyWith(
                  color:
                      isLiked ? AppColors.primary : AppColors.mutedForeground)),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: AppColors.primaryContainer,
          backgroundImage: comment.author.avatar != null
              ? CachedNetworkImageProvider(comment.author.avatar!)
              : null,
          child: comment.author.avatar == null
              ? Text(comment.author.name[0],
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primary))
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.author.name,
                        style: AppTextStyles.labelLarge),
                    const SizedBox(height: 2),
                    Text(comment.text, style: AppTextStyles.bodySmall
                        .copyWith(color: Theme.of(context).colorScheme.onSurface)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Row(
                  children: [
                    Text(
                      timeago.format(comment.createdAt, locale: 'fa'),
                      style: AppTextStyles.labelSmall,
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {},
                      child: Text('لایک',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: comment.isLiked
                                  ? AppColors.primary
                                  : AppColors.mutedForeground,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (comment.likesCount > 0) ...[
                      const SizedBox(width: 4),
                      Text('· ${comment.likesCount}',
                          style: AppTextStyles.labelSmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
