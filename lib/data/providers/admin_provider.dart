import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

class AdminProvider {
  final _dio = ApiClient.instance;

  Future<Map<String, dynamic>> getStats() async {
    final response = await _dio.get(ApiEndpoints.adminStats);
    return response.data as Map<String, dynamic>;
  }

  Future<List<UserModel>> getUsers({String? search}) async {
    final response = await _dio.get(
      ApiEndpoints.adminUsers,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final List data = response.data['data'] as List;
    return data
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PostModel>> getPosts({String? mediaType}) async {
    final response = await _dio.get(
      ApiEndpoints.adminPosts,
      queryParameters: {
        if (mediaType != null && mediaType != 'all') 'media_type': mediaType,
      },
    );
    final List data = response.data['data'] as List;
    return data
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> banUser(String id) async {
    final response = await _dio.post(ApiEndpoints.adminBanUser(id));
    return response.data as Map<String, dynamic>;
  }

  Future<void> deletePost(String id) async {
    await _dio.delete(ApiEndpoints.adminDeletePost(id));
  }
}
