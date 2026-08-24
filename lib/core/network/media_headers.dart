import '../storage/local_storage.dart';

/// Auth headers for direct media fetches.
///
/// The backend guards `/uploads` (see `middleware/mediaAccess.js`), so image and
/// video widgets that bypass Dio must carry the bearer token themselves.
/// [CachedNetworkImage] and [VideoPlayerController.networkUrl] both accept a
/// header map — pass these.
abstract class MediaHeaders {
  static Map<String, String> authHeaders() {
    final token = LocalStorage.token;
    if (token == null) return const {};
    return {'Authorization': 'Bearer $token'};
  }
}
