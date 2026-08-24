import 'package:get/get.dart';
import 'package:shirbrax/data/repositories/user_repository.dart';
import 'package:shirbrax/features/auth/controllers/auth_controller.dart';

/// Owns the account's privacy and subscription settings.
///
/// Writes go through [UserRepository] and the fresh user is pushed back into
/// [AuthController] so every screen bound to `auth.user` updates at once.
class AccessSettingsController extends GetxController {
  final _repo = UserRepository();
  final _auth = Get.find<AuthController>();

  final _isSaving = false.obs;
  final _error = ''.obs;

  bool get isSaving => _isSaving.value;
  String get error => _error.value;

  bool get isPrivate => _auth.user?.isPrivate ?? false;
  bool get subscriptionEnabled => _auth.user?.subscriptionEnabled ?? false;
  int get subscriptionPrice => _auth.user?.subscriptionPrice ?? 0;
  int get pendingRequestsCount => _auth.user?.pendingRequestsCount ?? 0;

  Future<void> setPrivate(bool value) => _save(isPrivate: value);

  /// Turning subscriptions on requires a price — the API rejects price <= 0,
  /// so ask for one here instead of round-tripping a failure.
  Future<bool> setSubscriptionEnabled(bool value, {int? price}) async {
    if (value && (price ?? subscriptionPrice) <= 0) {
      _error.value = 'برای فعال کردن اشتراک، قیمت ماهانه را وارد کنید.';
      return false;
    }
    return _save(
      subscriptionEnabled: value,
      subscriptionPrice: value ? (price ?? subscriptionPrice) : null,
    );
  }

  Future<bool> setPrice(int price) async {
    if (price <= 0) {
      _error.value = 'قیمت باید بیشتر از صفر باشد.';
      return false;
    }
    return _save(subscriptionPrice: price);
  }

  Future<bool> _save({
    bool? isPrivate,
    bool? subscriptionEnabled,
    int? subscriptionPrice,
  }) async {
    _error.value = '';
    _isSaving.value = true;
    try {
      final updated = await _repo.updatePrivacy(
        isPrivate: isPrivate,
        subscriptionEnabled: subscriptionEnabled,
        subscriptionPrice: subscriptionPrice,
      );
      _auth.setUser(updated);
      return true;
    } catch (e) {
      // ApiClient's error interceptor already surfaces a snackbar; keep the
      // message here for inline display.
      _error.value = 'ذخیره تنظیمات با خطا مواجه شد.';
      return false;
    } finally {
      _isSaving.value = false;
    }
  }
}
