import 'package:get/get.dart';
import 'package:shirbrax/data/models/user_model.dart';
import 'package:shirbrax/data/repositories/user_repository.dart';
import 'package:shirbrax/features/auth/controllers/auth_controller.dart';

/// Pending follow requests for the signed-in (private) account.
class FollowRequestsController extends GetxController {
  final _repo = UserRepository();
  final _auth = Get.find<AuthController>();

  final _requests = <UserModel>[].obs;
  final _isLoading = false.obs;
  final _busyIds = <String>{}.obs;

  List<UserModel> get requests => _requests;
  bool get isLoading => _isLoading.value;

  /// True while this specific request is being accepted or rejected, so only
  /// its own row shows a spinner.
  bool isBusy(String userId) => _busyIds.contains(userId);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    _isLoading.value = true;
    try {
      _requests.assignAll(await _repo.getFollowRequests());
    } catch (_) {
      _requests.clear();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> respond(String followerId, {required bool accept}) async {
    if (_busyIds.contains(followerId)) return;
    _busyIds.add(followerId);
    try {
      final result =
          await _repo.respondToFollowRequest(followerId, accept: accept);
      _requests.removeWhere((u) => u.id == followerId);

      // Keep the badge in settings/profile in sync with the server's count.
      final remaining = result['pending_requests_count'] as int?;
      final user = _auth.user;
      if (remaining != null && user != null) {
        _auth.setUser(user.copyWith(pendingRequestsCount: remaining));
      }
    } finally {
      _busyIds.remove(followerId);
    }
  }
}
