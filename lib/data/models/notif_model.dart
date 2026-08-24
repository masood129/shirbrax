/// Notification type
enum NotifType {
  like,
  comment,
  follow,
  mention,

  /// Someone asked to follow a private account.
  followRequest,

  /// A private account approved your request.
  followAccepted,

  /// Someone bought a subscription to your account.
  subscription,
}

/// Notification model
class NotifModel {
  final String id;
  final NotifType type;
  final String actorName;
  final String? actorAvatar;
  final String? postThumbnail;
  final String? postId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotifModel({
    required this.id,
    required this.type,
    required this.actorName,
    this.actorAvatar,
    this.postThumbnail,
    this.postId,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  NotifModel copyWith({bool? isRead}) => NotifModel(
        id: id,
        type: type,
        actorName: actorName,
        actorAvatar: actorAvatar,
        postThumbnail: postThumbnail,
        postId: postId,
        message: message,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  static List<NotifModel> get mockList => [
        NotifModel(
          id: '1',
          type: NotifType.like,
          actorName: 'سارا احمدی',
          actorAvatar: 'https://i.pravatar.cc/150?img=5',
          postThumbnail: 'https://picsum.photos/seed/1/100/100',
          postId: '1',
          message: 'پست شما را لایک کرد',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        NotifModel(
          id: '2',
          type: NotifType.follow,
          actorName: 'رضا کریمی',
          actorAvatar: 'https://i.pravatar.cc/150?img=7',
          message: 'شما را دنبال کرد',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        NotifModel(
          id: '3',
          type: NotifType.comment,
          actorName: 'مریم حسینی',
          actorAvatar: 'https://i.pravatar.cc/150?img=9',
          postThumbnail: 'https://picsum.photos/seed/3/100/100',
          postId: '3',
          message: 'نظر گذاشت: عکس فوق‌العاده‌ای است! 😍',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        NotifModel(
          id: '4',
          type: NotifType.like,
          actorName: 'حسن صادقی',
          actorAvatar: 'https://i.pravatar.cc/150?img=12',
          postThumbnail: 'https://picsum.photos/seed/2/100/100',
          postId: '2',
          message: 'پست شما را لایک کرد',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        NotifModel(
          id: '5',
          type: NotifType.mention,
          actorName: 'فاطمه رضایی',
          actorAvatar: 'https://i.pravatar.cc/150?img=16',
          postId: '4',
          message: 'شما را در یک پست منشن کرد',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        NotifModel(
          id: '6',
          type: NotifType.follow,
          actorName: 'کیان مشهدی',
          actorAvatar: 'https://i.pravatar.cc/150?img=20',
          message: 'شما را دنبال کرد',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
}
