import 'user_model.dart';

/// Media type for a post
enum MediaType { photo, video }

/// Who may open a post's media.
enum PostVisibility {
  /// Anyone who can see the account.
  public,

  /// Accepted followers only.
  followers,

  /// Paying subscribers only.
  subscribers,
}

/// Why the server withheld a post's media.
enum LockReason { privateAccount, followersOnly, subscribersOnly }

/// Photo or Video post
class PostModel {
  final String id;
  final UserModel author;
  final String? caption;
  final MediaType mediaType;

  /// Null when [isLocked] — the server never sends a usable URL for content
  /// the viewer may not open. Use [displayUrl] and guard on [isLocked].
  final String? mediaUrl;
  final String? thumbnailUrl; // video thumbnail or compressed photo
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final List<String> tags;
  final DateTime createdAt;

  // Video-specific
  final Duration? videoDuration;

  // ─── Access control ───────────────────────────────────────
  final PostVisibility visibility;

  /// The viewer may see this post exists but not open its media.
  final bool isLocked;
  final LockReason? lockReason;

  const PostModel({
    required this.id,
    required this.author,
    this.caption,
    required this.mediaType,
    this.mediaUrl,
    this.thumbnailUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.tags = const [],
    required this.createdAt,
    this.videoDuration,
    this.visibility = PostVisibility.public,
    this.isLocked = false,
    this.lockReason,
  });

  bool get isVideo => mediaType == MediaType.video;
  bool get isPhoto => mediaType == MediaType.photo;

  /// Null for a locked post — callers must render a lock placeholder instead.
  String? get displayUrl => isLocked ? null : (thumbnailUrl ?? mediaUrl);

  /// Whether unlocking this post is a matter of paying rather than following.
  bool get needsSubscription => lockReason == LockReason.subscribersOnly;

  static PostVisibility visibilityFromJson(dynamic value) {
    switch (value as String?) {
      case 'followers':
        return PostVisibility.followers;
      case 'subscribers':
        return PostVisibility.subscribers;
      default:
        return PostVisibility.public;
    }
  }

  static String visibilityToJson(PostVisibility visibility) {
    switch (visibility) {
      case PostVisibility.followers:
        return 'followers';
      case PostVisibility.subscribers:
        return 'subscribers';
      case PostVisibility.public:
        return 'public';
    }
  }

  static LockReason? lockReasonFromJson(dynamic value) {
    switch (value as String?) {
      case 'private_account':
        return LockReason.privateAccount;
      case 'followers_only':
        return LockReason.followersOnly;
      case 'subscribers_only':
        return LockReason.subscribersOnly;
      default:
        return null;
    }
  }

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'].toString(),
        author: UserModel.fromJson(json['author'] as Map<String, dynamic>),
        caption: json['caption'] as String?,
        mediaType: (json['media_type'] as String?) == 'video'
            ? MediaType.video
            : MediaType.photo,
        mediaUrl: json['media_url'] as String?,
        thumbnailUrl: json['thumbnail_url'] as String?,
        likesCount: json['likes_count'] as int? ?? 0,
        commentsCount: json['comments_count'] as int? ?? 0,
        isLiked: json['is_liked'] as bool? ?? false,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        createdAt: DateTime.parse(json['created_at'] as String),
        videoDuration: json['video_duration'] != null
            ? Duration(seconds: json['video_duration'] as int)
            : null,
        visibility: visibilityFromJson(json['visibility']),
        isLocked: json['is_locked'] as bool? ?? false,
        lockReason: lockReasonFromJson(json['lock_reason']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author.toJson(),
        'caption': caption,
        'media_type': isVideo ? 'video' : 'photo',
        'media_url': mediaUrl,
        'thumbnail_url': thumbnailUrl,
        'likes_count': likesCount,
        'comments_count': commentsCount,
        'is_liked': isLiked,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'video_duration': videoDuration?.inSeconds,
        'visibility': visibilityToJson(visibility),
        'is_locked': isLocked,
        'lock_reason': lockReason?.name,
      };

  PostModel copyWith({bool? isLiked, int? likesCount, int? commentsCount}) =>
      PostModel(
        id: id,
        author: author,
        caption: caption,
        mediaType: mediaType,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        isLiked: isLiked ?? this.isLiked,
        tags: tags,
        createdAt: createdAt,
        videoDuration: videoDuration,
        visibility: visibility,
        isLocked: isLocked,
        lockReason: lockReason,
      );

  // ─── Mock data ────────────────────────────────────────────
  static List<PostModel> get mockFeed => [
        PostModel(
          id: '1',
          author: UserModel.mockUser,
          caption: 'غروب زیبای دیروز 🌅',
          mediaType: MediaType.photo,
          mediaUrl: 'https://picsum.photos/seed/1/800/600',
          thumbnailUrl: 'https://picsum.photos/seed/1/400/300',
          likesCount: 42,
          commentsCount: 8,
          isLiked: true,
          tags: ['طبیعت', 'غروب'],
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        PostModel(
          id: '2',
          author: UserModel(
            id: '2',
            name: 'سارا احمدی',
            username: 'sara_a',
            email: 'sara@example.com',
            avatar: 'https://i.pravatar.cc/150?img=5',
            createdAt: DateTime(2024, 3, 1),
          ),
          caption: 'لحظات خوب با دوستان 💕',
          mediaType: MediaType.photo,
          mediaUrl: 'https://picsum.photos/seed/2/800/600',
          thumbnailUrl: 'https://picsum.photos/seed/2/400/300',
          likesCount: 87,
          commentsCount: 14,
          tags: ['دوستی'],
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        PostModel(
          id: '3',
          author: UserModel.mockUser,
          caption: 'کوه‌نوردی امروز 🏔',
          mediaType: MediaType.video,
          mediaUrl:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          thumbnailUrl: 'https://picsum.photos/seed/3/400/300',
          likesCount: 156,
          commentsCount: 23,
          videoDuration: const Duration(minutes: 1, seconds: 30),
          tags: ['ورزش', 'طبیعت'],
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        PostModel(
          id: '4',
          author: UserModel(
            id: '3',
            name: 'رضا کریمی',
            username: 'reza_k',
            email: 'reza@example.com',
            avatar: 'https://i.pravatar.cc/150?img=7',
            createdAt: DateTime(2024, 2, 10),
          ),
          caption: 'آشپزی آخر هفته 🍜',
          mediaType: MediaType.photo,
          mediaUrl: 'https://picsum.photos/seed/4/800/600',
          thumbnailUrl: 'https://picsum.photos/seed/4/400/300',
          likesCount: 31,
          commentsCount: 5,
          tags: ['آشپزی'],
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
}
