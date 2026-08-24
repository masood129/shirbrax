import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class StoryGroup {
  final UserModel user;
  final List<StoryDetail> items;

  StoryGroup({required this.user, required this.items});
}

class StoryDetail {
  final String id;
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;

  StoryDetail({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
  });
}

class StoryProvider {
  final _dio = ApiClient.instance;

  Future<List<StoryGroup>> getStories() async {
    final response = await _dio.get('/stories');
    final List data = response.data['data'] as List;
    return data.map((e) {
      final json = e as Map<String, dynamic>;
      final userJson = json['user'] as Map<String, dynamic>;
      final itemsJson = json['items'] as List;

      return StoryGroup(
        user: UserModel(
          id: userJson['id'].toString(),
          name: userJson['name'] as String,
          username: userJson['username'] as String,
          email: '',
          avatar: userJson['avatar'] as String?,
          createdAt: DateTime.now(),
        ),
        items: itemsJson.map((i) {
          final item = i as Map<String, dynamic>;
          return StoryDetail(
            id: item['id'].toString(),
            mediaUrl: item['media_url'] as String,
            mediaType: item['media_type'] as String? ?? 'photo',
            caption: item['caption'] as String?,
            createdAt: DateTime.parse(item['created_at'] as String),
            expiresAt: DateTime.parse(item['expires_at'] as String),
          );
        }).toList(),
      );
    }).toList();
  }

  Future<void> createStory({
    required String filePath,
    String? caption,
  }) async {
    final fileName = filePath.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'caption': ?caption,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    await _dio.post('/stories', data: formData);
  }
}
