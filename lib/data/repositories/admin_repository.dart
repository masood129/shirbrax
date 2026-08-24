import '../models/user_model.dart';
import '../models/post_model.dart';
import '../providers/admin_provider.dart';

class AdminRepository {
  final _provider = AdminProvider();

  Future<Map<String, dynamic>> getStats() => _provider.getStats();

  Future<List<UserModel>> getUsers({String? search}) =>
      _provider.getUsers(search: search);

  Future<List<PostModel>> getPosts({String? mediaType}) =>
      _provider.getPosts(mediaType: mediaType);

  Future<Map<String, dynamic>> banUser(String id) =>
      _provider.banUser(id);

  Future<void> deletePost(String id) => _provider.deletePost(id);
}
