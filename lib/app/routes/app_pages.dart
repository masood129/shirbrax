import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import 'package:shirbrax/features/auth/views/login_view.dart';
import 'package:shirbrax/features/auth/views/register_view.dart';
import 'package:shirbrax/features/home/views/home_view.dart';
import 'package:shirbrax/features/explore/views/explore_view.dart';
import 'package:shirbrax/features/media/views/media_detail_view.dart';
import 'package:shirbrax/features/media/views/upload_view.dart';
import 'package:shirbrax/features/profile/controllers/follow_requests_controller.dart';
import 'package:shirbrax/features/profile/views/follow_requests_view.dart';
import 'package:shirbrax/features/profile/views/profile_view.dart';
import 'package:shirbrax/features/notifications/views/notifications_view.dart';
import 'package:shirbrax/features/settings/controllers/access_settings_controller.dart';
import 'package:shirbrax/features/settings/views/access_settings_view.dart';
import 'package:shirbrax/features/settings/views/settings_view.dart';
import 'package:shirbrax/features/settings/views/edit_profile_view.dart';
import 'package:shirbrax/features/admin/views/admin_dashboard_view.dart';
import 'package:shirbrax/features/admin/views/admin_users_view.dart';
import 'package:shirbrax/features/admin/views/admin_posts_view.dart';
import 'package:shirbrax/shared/widgets/adaptive_scaffold.dart';

/// GoRouter with role-based access control
class AppPages {
  AppPages._();

  static final _box = GetStorage();

  static String? _getToken() => _box.read<String>('token');
  static String? _getRole() => _box.read<String>('role');

  static bool get _isLoggedIn => _getToken() != null;
  static bool get _isAdmin => _getRole() == 'admin';

  static final router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final loggedIn = _isLoggedIn;
      final location = state.matchedLocation;

      // ─── Splash → always redirect ──────────────────────────
      if (location == AppRoutes.splash) {
        return loggedIn ? AppRoutes.home : AppRoutes.login;
      }

      final onAuth = location == AppRoutes.login ||
          location == AppRoutes.register;

      // Not logged in → go to login
      if (!loggedIn && !onAuth) return AppRoutes.login;

      // Already logged in on auth pages → go to home
      if (loggedIn && onAuth) return AppRoutes.home;

      // Admin routes → check role
      if (location.startsWith('/admin') && !_isAdmin) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // ─── Splash / Root ──────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SizedBox.shrink(),
      ),

      // ─── Auth ───────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterView(),
      ),

      // ─── Main Shell (with AdaptiveScaffold) ─────────────────
      ShellRoute(
        builder: (context, state, child) => AdaptiveScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeView(),
            ),
          ),
          GoRoute(
            path: AppRoutes.explore,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExploreView(),
            ),
          ),
          GoRoute(
            path: AppRoutes.upload,
            builder: (context, state) => const UploadView(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotificationsView(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProfileView(userId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsView(),
          ),
          GoRoute(
            path: AppRoutes.editProfile,
            builder: (context, state) => const EditProfileView(),
          ),
          // Route-scoped controllers are registered here — go_router leaves DI
          // to us, and this keeps Get.put out of build().
          GoRoute(
            path: AppRoutes.accessSettings,
            builder: (context, state) {
              Get.put(AccessSettingsController());
              return const AccessSettingsView();
            },
          ),
          GoRoute(
            path: AppRoutes.followRequests,
            builder: (context, state) {
              Get.put(FollowRequestsController());
              return const FollowRequestsView();
            },
          ),
          GoRoute(
            path: AppRoutes.mediaDetail,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return MediaDetailView(mediaId: id);
            },
          ),
        ],
      ),

      // ─── Admin Shell ────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            AdaptiveScaffold(isAdmin: true, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.adminDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminDashboardView(),
            ),
          ),
          GoRoute(
            path: AppRoutes.adminUsers,
            builder: (context, state) => const AdminUsersView(),
          ),
          GoRoute(
            path: AppRoutes.adminPosts,
            builder: (context, state) => const AdminPostsView(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsView(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('صفحه یافت نشد', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('بازگشت به خانه'),
            ),
          ],
        ),
      ),
    ),
  );
}
