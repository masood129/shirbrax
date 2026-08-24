import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class PostProvider {
  final _dio = ApiClient.instance;

  Future<List<PostModel>> getFeed({int page = 1, int perPage = 10, String? userId}) async {
    final response = await _dio.get(
      ApiEndpoints.posts,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        'user_id': ?userId,
      },
    );
    final List data = response.data['data'] as List;
    return data
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PostModel>> getExplorePosts({String? query}) async {
    final response = await _dio.get(
      '${ApiEndpoints.posts}/explore',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'query': query,
      },
    );
    final List data = response.data['data'] as List;
    return data
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PostModel> getPost(String id) async {
    final response = await _dio.get(ApiEndpoints.postById(id));
    return PostModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> likePost(String id) async {
    final response = await _dio.post(ApiEndpoints.postLike(id));
    return response.data as Map<String, dynamic>;
  }

  Future<PostModel> createPost({
    required String caption,
    required String mediaType,
    required String filePath,
    List<String> tags = const [],
    PostVisibility visibility = PostVisibility.public,
  }) async {
    final fileName = filePath.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'caption': caption,
      'media_type': mediaType,
      'tags': tags.join(','),
      'visibility': PostModel.visibilityToJson(visibility),
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _dio.post(
      ApiEndpoints.uploadMedia,
      data: formData,
    );
    return PostModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePost(String id) async {
    await _dio.delete(ApiEndpoints.postById(id));
  }

  Future<List<CommentModel>> getComments(String postId) async {
    final response = await _dio.get(ApiEndpoints.postComments(postId));
    final List data = response.data['data'] as List;
    return data
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommentModel> addComment(String postId, String text) async {
    final response = await _dio.post(
      ApiEndpoints.postComments(postId),
      data: {'text': text},
    );
    return CommentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> likeComment(String postId, String commentId) async {
    await _dio.post('${ApiEndpoints.postComments(postId)}/$commentId/like');
  }
}
