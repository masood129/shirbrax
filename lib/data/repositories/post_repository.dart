import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../providers/post_provider.dart';

class PostRepository {
  final _provider = PostProvider();

  Future<List<PostModel>> getFeed({int page = 1, int perPage = 10, String? userId}) =>
      _provider.getFeed(page: page, perPage: perPage, userId: userId);

  Future<List<PostModel>> getExplorePosts({String? query}) =>
      _provider.getExplorePosts(query: query);

  Future<PostModel> getPost(String id) => _provider.getPost(id);

  Future<Map<String, dynamic>> likePost(String id) => _provider.likePost(id);

  Future<PostModel> createPost({
    required String caption,
    required String mediaType,
    required String filePath,
    List<String> tags = const [],
    PostVisibility visibility = PostVisibility.public,
  }) =>
      _provider.createPost(
        caption: caption,
        mediaType: mediaType,
        filePath: filePath,
        tags: tags,
        visibility: visibility,
      );

  Future<void> deletePost(String id) => _provider.deletePost(id);

  Future<List<CommentModel>> getComments(String postId) =>
      _provider.getComments(postId);

  Future<CommentModel> addComment(String postId, String text) =>
      _provider.addComment(postId, text);

  Future<void> likeComment(String postId, String commentId) =>
      _provider.likeComment(postId, commentId);
}
