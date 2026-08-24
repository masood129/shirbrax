import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

class UserProvider {
  final _dio = ApiClient.instance;

  Future<List<UserModel>> getUsers({String? search}) async {
    final response = await _dio.get(
      ApiEndpoints.users,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final List data = response.data['data'] as List;
    return data
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserModel> getUser(String id) async {
    final response = await _dio.get(ApiEndpoints.userById(id));
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PostModel>> getUserPosts(String id) async {
    final response = await _dio.get(ApiEndpoints.userPosts(id));
    final List data = response.data['data'] as List;
    return data
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> followUser(String id) async {
    final response = await _dio.post(ApiEndpoints.followUser(id));
    return response.data as Map<String, dynamic>;
  }

  Future<UserModel> updateProfile({
    String? name,
    String? username,
    String? bio,
    String? avatarFilePath,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (username != null) data['username'] = username;
    if (bio != null) data['bio'] = bio;

    if (avatarFilePath != null) {
      final fileName = avatarFilePath.split(Platform.pathSeparator).last;
      data['avatar'] = await MultipartFile.fromFile(
        avatarFilePath,
        filename: fileName,
      );
    }

    final formData = FormData.fromMap(data);
    final response = await _dio.put(
      '${ApiEndpoints.users}/profile',
      data: formData,
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Privacy & subscription settings (own account) ─────────

  Future<UserModel> updatePrivacy({
    bool? isPrivate,
    bool? subscriptionEnabled,
    int? subscriptionPrice,
  }) async {
    final response = await _dio.put(
      ApiEndpoints.privacySettings,
      data: {
        if (isPrivate != null) 'is_private': isPrivate,
        if (subscriptionEnabled != null)
          'subscription_enabled': subscriptionEnabled,
        if (subscriptionPrice != null) 'subscription_price': subscriptionPrice,
      },
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Follow requests (own account) ─────────────────────────

  Future<List<UserModel>> getFollowRequests() async {
    final response = await _dio.get(ApiEndpoints.followRequests);
    final List data = response.data['data'] as List;
    return data
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> respondToFollowRequest(
    String followerId, {
    required bool accept,
  }) async {
    final response = await _dio.post(
      accept
          ? ApiEndpoints.acceptFollowRequest(followerId)
          : ApiEndpoints.rejectFollowRequest(followerId),
    );
    return response.data as Map<String, dynamic>;
  }

  // ─── Subscriptions ─────────────────────────────────────────

  Future<Map<String, dynamic>> subscribe(String creatorId,
      {int months = 1}) async {
    final response = await _dio.post(
      ApiEndpoints.subscribe(creatorId),
      data: {'months': months},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelSubscription(String creatorId) async {
    final response = await _dio.delete(ApiEndpoints.subscribe(creatorId));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSubscriptionStatus(String creatorId) async {
    final response = await _dio.get(ApiEndpoints.subscriptionStatus(creatorId));
    return response.data as Map<String, dynamic>;
  }
}
