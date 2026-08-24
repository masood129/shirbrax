import '../models/user_model.dart';
import '../models/post_model.dart';
import '../providers/user_provider.dart';

class UserRepository {
  final _provider = UserProvider();

  Future<List<UserModel>> getUsers({String? search}) =>
      _provider.getUsers(search: search);

  Future<UserModel> getUser(String id) => _provider.getUser(id);

  Future<List<PostModel>> getUserPosts(String id) =>
      _provider.getUserPosts(id);

  Future<Map<String, dynamic>> followUser(String id) =>
      _provider.followUser(id);

  Future<UserModel> updateProfile({
    String? name,
    String? username,
    String? bio,
    String? avatarFilePath,
  }) =>
      _provider.updateProfile(
        name: name,
        username: username,
        bio: bio,
        avatarFilePath: avatarFilePath,
      );

  // ─── Privacy & subscription settings ───────────────────────

  Future<UserModel> updatePrivacy({
    bool? isPrivate,
    bool? subscriptionEnabled,
    int? subscriptionPrice,
  }) =>
      _provider.updatePrivacy(
        isPrivate: isPrivate,
        subscriptionEnabled: subscriptionEnabled,
        subscriptionPrice: subscriptionPrice,
      );

  // ─── Follow requests ───────────────────────────────────────

  Future<List<UserModel>> getFollowRequests() => _provider.getFollowRequests();

  Future<Map<String, dynamic>> respondToFollowRequest(
    String followerId, {
    required bool accept,
  }) =>
      _provider.respondToFollowRequest(followerId, accept: accept);

  // ─── Subscriptions ─────────────────────────────────────────

  Future<Map<String, dynamic>> subscribe(String creatorId, {int months = 1}) =>
      _provider.subscribe(creatorId, months: months);

  Future<Map<String, dynamic>> cancelSubscription(String creatorId) =>
      _provider.cancelSubscription(creatorId);

  Future<Map<String, dynamic>> getSubscriptionStatus(String creatorId) =>
      _provider.getSubscriptionStatus(creatorId);
}
