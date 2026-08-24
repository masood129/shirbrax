import 'user_model.dart';

/// Comment on a post
class CommentModel {
  final String id;
  final String postId;
  final UserModel author;
  final String text;
  final int likesCount;
  final bool isLiked;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.author,
    required this.text,
    this.likesCount = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  CommentModel copyWith({bool? isLiked, int? likesCount}) => CommentModel(
        id: id,
        postId: postId,
        author: author,
        text: text,
        likesCount: likesCount ?? this.likesCount,
        isLiked: isLiked ?? this.isLiked,
        createdAt: createdAt,
      );

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id: json['id'].toString(),
        postId: json['post_id'].toString(),
        author: UserModel.fromJson(json['author'] as Map<String, dynamic>),
        text: json['text'] as String,
        likesCount: json['likes_count'] as int? ?? 0,
        isLiked: json['is_liked'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  static List<CommentModel> mockFor(String postId) => [
        CommentModel(
          id: '1',
          postId: postId,
          author: UserModel(
            id: '2',
            name: 'سارا احمدی',
            username: 'sara_a',
            email: 'sara@example.com',
            avatar: 'https://i.pravatar.cc/150?img=5',
            createdAt: DateTime(2024, 3, 1),
          ),
          text: 'عکس فوق‌العاده‌ای است! 😍',
          likesCount: 5,
          isLiked: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        CommentModel(
          id: '2',
          postId: postId,
          author: UserModel(
            id: '3',
            name: 'رضا کریمی',
            username: 'reza_k',
            email: 'reza@example.com',
            avatar: 'https://i.pravatar.cc/150?img=7',
            createdAt: DateTime(2024, 2, 10),
          ),
          text: 'کجای ایران گرفتی؟ 🏔',
          likesCount: 2,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        CommentModel(
          id: '3',
          postId: postId,
          author: UserModel.mockUser,
          text: 'خیلی زیباست 🌟',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];
}
