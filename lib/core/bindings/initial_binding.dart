import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../network/api_client.dart';
import 'package:shirbrax/shared/controllers/theme_controller.dart';
import 'package:shirbrax/features/auth/controllers/auth_controller.dart';

/// Initial GetX dependency injection
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Storage
    Get.put(GetStorage(), permanent: true);

    // Theme
    Get.put(ThemeController(), permanent: true);

    // Network
    Get.lazyPut(() => ApiClient.instance, fenix: true);

    // Auth (permanent — needed across all routes)
    Get.put(AuthController(), permanent: true);
  }
}
