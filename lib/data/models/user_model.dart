/// Follow relationship state between the viewer and this user.
enum FollowStatus { none, pending, accepted }

/// User model
class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? avatar;
  final String? bio;
  final String role; // 'user' | 'admin'
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isFollowing;
  final bool isBanned;
  final DateTime createdAt;

  // ─── Privacy & subscription ───────────────────────────────
  /// Account is private: posts and stories need an accepted follow.
  final bool isPrivate;

  /// This account sells a paid subscription.
  final bool subscriptionEnabled;

  /// Monthly price in Toman. 0 when subscriptions are off.
  final int subscriptionPrice;

  /// Viewer's follow state — distinguishes a pending request from a follow.
  final FollowStatus followStatus;

  /// Viewer holds an active (paid, unexpired) subscription to this account.
  final bool isSubscribed;
  final DateTime? subscriptionExpiresAt;

  /// False when the viewer may not browse this account's posts at all.
  final bool canViewPosts;

  /// Follow requests waiting for approval. Only meaningful for your own account.
  final int pendingRequestsCount;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.avatar,
    this.bio,
    this.role = 'user',
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isFollowing = false,
    this.isBanned = false,
    required this.createdAt,
    this.isPrivate = false,
    this.subscriptionEnabled = false,
    this.subscriptionPrice = 0,
    this.followStatus = FollowStatus.none,
    this.isSubscribed = false,
    this.subscriptionExpiresAt,
    this.canViewPosts = true,
    this.pendingRequestsCount = 0,
  });

  bool get isAdmin => role == 'admin';

  /// A follow request was sent but not yet approved.
  bool get isFollowPending => followStatus == FollowStatus.pending;

  /// Show a "subscribe" call to action for this account.
  bool get canSubscribe => subscriptionEnabled && !isSubscribed;

  static FollowStatus followStatusFromJson(dynamic value) {
    switch (value as String?) {
      case 'accepted':
        return FollowStatus.accepted;
      case 'pending':
        return FollowStatus.pending;
      default:
        return FollowStatus.none;
    }
  }

  static String followStatusToJson(FollowStatus status) => status.name;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'].toString(),
        name: json['name'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        avatar: json['avatar'] as String?,
        bio: json['bio'] as String?,
        role: json['role'] as String? ?? 'user',
        followersCount: json['followers_count'] as int? ?? 0,
        followingCount: json['following_count'] as int? ?? 0,
        postsCount: json['posts_count'] as int? ?? 0,
        isFollowing: json['is_following'] as bool? ?? false,
        isBanned: json['is_banned'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        isPrivate: json['is_private'] as bool? ?? false,
        subscriptionEnabled: json['subscription_enabled'] as bool? ?? false,
        subscriptionPrice: json['subscription_price'] as int? ?? 0,
        followStatus: followStatusFromJson(json['follow_status']),
        isSubscribed: json['is_subscribed'] as bool? ?? false,
        subscriptionExpiresAt: json['subscription_expires_at'] != null
            ? DateTime.tryParse(json['subscription_expires_at'] as String)
            : null,
        canViewPosts: json['can_view_posts'] as bool? ?? true,
        pendingRequestsCount: json['pending_requests_count'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'email': email,
        'avatar': avatar,
        'bio': bio,
        'role': role,
        'followers_count': followersCount,
        'following_count': followingCount,
        'posts_count': postsCount,
        'is_following': isFollowing,
        'is_banned': isBanned,
        'created_at': createdAt.toIso8601String(),
        'is_private': isPrivate,
        'subscription_enabled': subscriptionEnabled,
        'subscription_price': subscriptionPrice,
        'follow_status': followStatusToJson(followStatus),
        'is_subscribed': isSubscribed,
        'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
        'can_view_posts': canViewPosts,
        'pending_requests_count': pendingRequestsCount,
      };

  UserModel copyWith({
    String? name,
    String? avatar,
    String? bio,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
    bool? isBanned,
    bool? isPrivate,
    bool? subscriptionEnabled,
    int? subscriptionPrice,
    FollowStatus? followStatus,
    bool? isSubscribed,
    DateTime? subscriptionExpiresAt,
    bool? canViewPosts,
    int? pendingRequestsCount,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        username: username,
        email: email,
        avatar: avatar ?? this.avatar,
        bio: bio ?? this.bio,
        role: role,
        followersCount: followersCount ?? this.followersCount,
        followingCount: followingCount ?? this.followingCount,
        postsCount: postsCount,
        isFollowing: isFollowing ?? this.isFollowing,
        isBanned: isBanned ?? this.isBanned,
        createdAt: createdAt,
        isPrivate: isPrivate ?? this.isPrivate,
        subscriptionEnabled: subscriptionEnabled ?? this.subscriptionEnabled,
        subscriptionPrice: subscriptionPrice ?? this.subscriptionPrice,
        followStatus: followStatus ?? this.followStatus,
        isSubscribed: isSubscribed ?? this.isSubscribed,
        subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
        canViewPosts: canViewPosts ?? this.canViewPosts,
        pendingRequestsCount: pendingRequestsCount ?? this.pendingRequestsCount,
      );

  // ─── Mock data ────────────────────────────────────────────
  static UserModel get mockUser => UserModel(
        id: '1',
        name: 'علی محمدی',
        username: 'ali_m',
        email: 'ali@example.com',
        avatar: 'https://i.pravatar.cc/150?img=3',
        bio: 'عاشق عکاسی و سفر 📸',
        role: 'user',
        followersCount: 128,
        followingCount: 64,
        postsCount: 32,
        createdAt: DateTime(2024, 1, 15),
      );

  static UserModel get mockAdmin => UserModel(
        id: '0',
        name: 'مدیر سیستم',
        username: 'admin',
        email: 'admin@shirbrax.ir',
        role: 'admin',
        createdAt: DateTime(2024, 1, 1),
      );
}
