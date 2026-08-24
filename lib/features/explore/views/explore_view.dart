import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/app/routes/app_routes.dart';
import 'package:shirbrax/core/network/media_headers.dart';
import 'package:shirbrax/core/utils/responsive_helper.dart';
import 'package:shirbrax/data/models/post_model.dart';
import 'package:shirbrax/data/models/user_model.dart';
import 'package:shirbrax/data/repositories/post_repository.dart';
import 'package:shirbrax/data/repositories/user_repository.dart';
import 'package:shirbrax/shared/widgets/locked_media.dart';

class ExploreView extends StatefulWidget {
  const ExploreView({super.key});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  final _postRepo = PostRepository();
  final _userRepo = UserRepository();

  String _query = '';
  List<PostModel> _allPosts = [];
  List<UserModel> _userResults = [];
  bool _isLoading = false;

  final List<String> _trendingTags = [
    'طبیعت', 'عکاسی', 'سفر', 'آشپزی', 'ورزش', 'موسیقی', 'هنر', 'فناوری',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadExplore();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExplore() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _postRepo.getExplorePosts(query: _query);
      List<UserModel> users = [];
      if (_query.isNotEmpty) {
        users = await _userRepo.getUsers(search: _query);
      }
      if (mounted) {
        setState(() {
          _allPosts = posts;
          _userResults = users;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allPosts = PostModel.mockFeed;
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String val) {
    setState(() => _query = val.trim());
    _loadExplore();
  }

  List<PostModel> get _photos =>
      _allPosts.where((p) => p.isPhoto).toList();
  List<PostModel> get _videos =>
      _allPosts.where((p) => p.isVideo).toList();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = ResponsiveHelper.feedColumns(width) + 1;

    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(),
        toolbarHeight: 64,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'همه'),
            Tab(text: 'عکس'),
            Tab(text: 'ویدیو'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _query.isNotEmpty && _userResults.isNotEmpty
              ? _buildUserResults()
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildGrid(_allPosts, cols),
                    _buildGrid(_photos, cols),
                    _buildGrid(_videos, cols),
                  ],
                ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        hintText: 'جستجو در پست‌ها، تگ‌ها و کاربران...',
        hintStyle: AppTextStyles.bodySmall,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  _onSearchChanged('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      onSubmitted: _onSearchChanged,
    );
  }

  Widget _buildUserResults() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('کاربران', style: AppTextStyles.titleMedium),
          ),
          ..._userResults.map(
            (u) => ListTile(
              leading: CircleAvatar(
                backgroundImage: u.avatar != null
                    ? CachedNetworkImageProvider(u.avatar!)
                    : null,
                child: u.avatar == null ? Text(u.name[0]) : null,
              ),
              title: Text(u.name, style: AppTextStyles.titleSmall),
              subtitle: Text('@${u.username}'),
              trailing: OutlinedButton(
                onPressed: () => context.go(AppRoutes.profilePath(u.id)),
                child: const Text('مشاهده پروفایل'),
              ),
              onTap: () => context.go(AppRoutes.profilePath(u.id)),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('پست‌ها', style: AppTextStyles.titleMedium),
          ),
          SizedBox(
            height: 400,
            child: _buildGrid(_allPosts, 3),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<PostModel> posts, int cols) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.mutedForeground),
            const SizedBox(height: 12),
            Text('نتیجه‌ای یافت نشد',
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.mutedForeground)),
            if (_query.isEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: _trendingTags
                      .map((tag) => ActionChip(
                            label: Text('#$tag'),
                            onPressed: () {
                              _searchCtrl.text = tag;
                              _onSearchChanged(tag);
                            },
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExplore,
      child: CustomScrollView(
        slivers: [
          // Trending tags header (only when no query)
          if (_query.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تگ‌های پرطرفدار', style: AppTextStyles.titleSmall),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _trendingTags.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => ActionChip(
                          label: Text('#${_trendingTags[i]}',
                              style: AppTextStyles.labelSmall),
                          onPressed: () {
                            _searchCtrl.text = _trendingTags[i];
                            _onSearchChanged(_trendingTags[i]);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.all(2),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _GridThumb(post: posts[i])
                    .animate()
                    .fadeIn(delay: (i * 30).ms),
                childCount: posts.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridThumb extends StatelessWidget {
  final PostModel post;
  const _GridThumb({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.mediaPath(post.id)),
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
              placeholder: (_, _) => Container(color: AppColors.muted),
            ),
          if (post.isVideo)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.videocam_rounded,
                  color: Colors.white, size: 18,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black)]),
            ),
          Positioned(
            bottom: 6,
            left: 6,
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 12,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)]),
                const SizedBox(width: 2),
                Text('${post.likesCount}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: Colors.white,
                            shadows: const [Shadow(blurRadius: 4, color: Colors.black)])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
