/// ShirBrax Route Names
abstract class AppRoutes {
  // ─── Auth ─────────────────────────────────────────────────
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';

  // ─── User ─────────────────────────────────────────────────
  static const home = '/home';
  static const explore = '/explore';
  static const search = '/search';
  static const upload = '/upload';
  static const mediaDetail = '/media/:id';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const editProfile = '/edit-profile';
  static const accessSettings = '/access-settings';
  static const followRequests = '/follow-requests';
  static const story = '/story/:userId';

  // ─── Profile ──────────────────────────────────────────────
  static const profile = '/profile/:id';

  // ─── Admin ────────────────────────────────────────────────
  static const adminDashboard = '/admin';
  static const adminUsers = '/admin/users';
  static const adminPosts = '/admin/posts';

  // ─── Helpers ──────────────────────────────────────────────
  static String profilePath(String id) => '/profile/$id';
  static String mediaPath(String id) => '/media/$id';
  static String storyPath(String userId) => '/story/$userId';
}
