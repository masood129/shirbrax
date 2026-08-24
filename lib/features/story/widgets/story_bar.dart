import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/data/models/user_model.dart';
import 'package:shirbrax/data/repositories/story_repository.dart';

/// Story item in the horizontal story bar
class StoryItem {
  final UserModel user;
  final String imageUrl;
  final bool isSeen;
  const StoryItem({
    required this.user,
    required this.imageUrl,
    this.isSeen = false,
  });

  static List<StoryItem> get mockStories => [
        StoryItem(
          user: UserModel.mockUser,
          imageUrl: 'https://picsum.photos/seed/s1/500/900',
          isSeen: false,
        ),
        StoryItem(
          user: UserModel(
            id: '2',
            name: 'سارا احمدی',
            username: 'sara_a',
            email: 'sara@example.com',
            avatar: 'https://i.pravatar.cc/150?img=5',
            createdAt: DateTime.now(),
          ),
          imageUrl: 'https://picsum.photos/seed/s2/500/900',
          isSeen: false,
        ),
        StoryItem(
          user: UserModel(
            id: '3',
            name: 'رضا کریمی',
            username: 'reza_k',
            email: 'reza@example.com',
            avatar: 'https://i.pravatar.cc/150?img=7',
            createdAt: DateTime.now(),
          ),
          imageUrl: 'https://picsum.photos/seed/s3/500/900',
          isSeen: true,
        ),
        StoryItem(
          user: UserModel(
            id: '4',
            name: 'مریم حسینی',
            username: 'maryam_h',
            email: 'maryam@example.com',
            avatar: 'https://i.pravatar.cc/150?img=9',
            createdAt: DateTime.now(),
          ),
          imageUrl: 'https://picsum.photos/seed/s4/500/900',
          isSeen: true,
        ),
        StoryItem(
          user: UserModel(
            id: '5',
            name: 'حسن صادقی',
            username: 'hasan_s',
            email: 'hasan@example.com',
            avatar: 'https://i.pravatar.cc/150?img=12',
            createdAt: DateTime.now(),
          ),
          imageUrl: 'https://picsum.photos/seed/s5/500/900',
          isSeen: false,
        ),
      ];
}

/// Horizontal story bar widget for home feed top
class StoryBar extends StatefulWidget {
  const StoryBar({super.key});

  @override
  State<StoryBar> createState() => _StoryBarState();
}

class _StoryBarState extends State<StoryBar> {
  final _storyRepo = StoryRepository();
  List<StoryItem> _stories = [];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      final groups = await _storyRepo.getStories();
      if (groups.isNotEmpty) {
        final items = groups.map((g) {
          final firstMedia = g.items.isNotEmpty ? g.items.first.mediaUrl : 'https://picsum.photos/seed/s1/500/900';
          return StoryItem(
            user: g.user,
            imageUrl: firstMedia,
            isSeen: false,
          );
        }).toList();
        if (mounted) {
          setState(() => _stories = items);
        }
      } else {
        if (mounted) {
          setState(() => _stories = StoryItem.mockStories);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _stories = StoryItem.mockStories);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = _stories.isEmpty ? StoryItem.mockStories : _stories;
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: stories.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) return const _AddStoryButton();
          return _StoryAvatar(item: stories[i - 1], index: i - 1);
        },
      ),
    );
  }
}

class _AddStoryButton extends StatelessWidget {
  const _AddStoryButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(Icons.add_rounded, color: AppColors.primary),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded,
                      size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('استوری',
              style: AppTextStyles.labelSmall
                  .copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final StoryItem item;
  final int index;
  const _StoryAvatar({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openStory(context, index),
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: item.isSeen
                    ? null
                    : AppColors.gradientPrimary,
                border: item.isSeen
                    ? Border.all(color: AppColors.border, width: 2)
                    : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).colorScheme.surface, width: 2),
                ),
                child: CircleAvatar(
                  backgroundImage: item.user.avatar != null
                      ? CachedNetworkImageProvider(item.user.avatar!)
                      : null,
                  backgroundColor: AppColors.primaryContainer,
                  child: item.user.avatar == null
                      ? Text(item.user.name[0])
                      : null,
                ),
              ),
            ).animate().scale(delay: (index * 60).ms),
            const SizedBox(height: 4),
            Text(
              item.user.name.split(' ').first,
              style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _openStory(BuildContext context, int startIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => FadeTransition(
          opacity: anim,
          child: StoryViewer(
            stories: StoryItem.mockStories,
            initialIndex: startIndex,
          ),
        ),
        opaque: false,
      ),
    );
  }
}

/// Full-screen Story Viewer with progress bar
class StoryViewer extends StatefulWidget {
  final List<StoryItem> stories;
  final int initialIndex;
  const StoryViewer(
      {super.key, required this.stories, required this.initialIndex});

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      })
      ..forward();
  }

  void _next() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _progressCtrl.forward(from: 0);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _progressCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final x = details.globalPosition.dx;
          final mid = MediaQuery.sizeOf(context).width / 2;
          x < mid ? _prev() : _next();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            CachedNetworkImage(
              imageUrl: story.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: Colors.black),
            ),
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xAA000000), Colors.transparent, Color(0x66000000)],
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
            // Progress bars
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 12,
              right: 12,
              child: Row(
                children: List.generate(widget.stories.length, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.white30,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerRight,
                        widthFactor: i < _currentIndex
                            ? 1
                            : i == _currentIndex
                                ? _progressCtrl.value
                                : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Author
            Positioned(
              top: MediaQuery.paddingOf(context).top + 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: story.user.avatar != null
                        ? CachedNetworkImageProvider(story.user.avatar!)
                        : null,
                    child: story.user.avatar == null
                        ? Text(story.user.name[0])
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(story.user.name,
                      style: AppTextStyles.titleSmall
                          .copyWith(color: Colors.white)),
                  const Spacer(),
                  IconButton(
                    icon:
                        const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
