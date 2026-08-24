import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// ShirBrax API Endpoints
abstract class ApiEndpoints {
  // ─── Base ──────────────────────────────────────────────────
  /// Dynamic baseUrl: 'http://10.0.2.2:3000/api/v1' (Android Emulator) or 'http://localhost:3000/api/v1' (Web/Desktop/iOS)
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:3000/api/v1';
  }

  // ─── Auth ──────────────────────────────────────────────────
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const logout = '/auth/logout';
  static const refreshToken = '/auth/refresh';
  static const me = '/auth/me';

  // ─── Posts (Photos & Videos) ───────────────────────────────
  static const posts = '/posts';
  static String postById(String id) => '/posts/$id';
  static String postLike(String id) => '/posts/$id/like';
  static String postComments(String id) => '/posts/$id/comments';
  static const uploadMedia = '/posts/upload';

  // ─── Users ────────────────────────────────────────────────
  static const users = '/users';
  static String userById(String id) => '/users/$id';
  static String userPosts(String id) => '/users/$id/posts';
  static String followUser(String id) => '/users/$id/follow';

  // ─── Privacy & Follow Requests ────────────────────────────
  static const privacySettings = '/users/privacy';
  static const followRequests = '/users/follow-requests';
  static String acceptFollowRequest(String followerId) =>
      '/users/follow-requests/$followerId/accept';
  static String rejectFollowRequest(String followerId) =>
      '/users/follow-requests/$followerId/reject';

  // ─── Subscriptions ────────────────────────────────────────
  static String subscribe(String creatorId) => '/users/$creatorId/subscribe';
  static String subscriptionStatus(String creatorId) =>
      '/users/$creatorId/subscription';

  // ─── Admin ────────────────────────────────────────────────
  static const adminStats = '/admin/stats';
  static const adminUsers = '/admin/users';
  static const adminPosts = '/admin/posts';
  static String adminBanUser(String id) => '/admin/users/$id/ban';
  static String adminDeletePost(String id) => '/admin/posts/$id';
}
