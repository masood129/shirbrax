import 'package:get_storage/get_storage.dart';

/// Local storage wrapper using GetStorage
class LocalStorage {
  static final _box = GetStorage();

  // ─── Auth ─────────────────────────────────────────────────
  static const _keyToken = 'token';
  static const _keyRole = 'role';
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyThemeMode = 'theme_mode';

  // Token
  static String? get token => _box.read<String>(_keyToken);
  static Future<void> setToken(String token) => _box.write(_keyToken, token);

  // Role
  static String? get role => _box.read<String>(_keyRole);
  static Future<void> setRole(String role) => _box.write(_keyRole, role);

  // User info
  static String? get userId => _box.read<String>(_keyUserId);
  static Future<void> setUserId(String id) => _box.write(_keyUserId, id);

  static String? get userName => _box.read<String>(_keyUserName);
  static Future<void> setUserName(String name) =>
      _box.write(_keyUserName, name);

  // Theme
  static bool get isDarkMode =>
      _box.read<bool>(_keyThemeMode) ?? false;
  static Future<void> setDarkMode(bool value) =>
      _box.write(_keyThemeMode, value);

  // ─── Auth helpers ─────────────────────────────────────────
  static bool get isLoggedIn => token != null;
  static bool get isAdmin => role == 'admin';

  static Future<void> saveAuthData({
    required String token,
    required String role,
    required String userId,
    required String userName,
  }) async {
    await setToken(token);
    await setRole(role);
    await setUserId(userId);
    await setUserName(userName);
  }

  static Future<void> clearAuth() async {
    await _box.remove(_keyToken);
    await _box.remove(_keyRole);
    await _box.remove(_keyUserId);
    await _box.remove(_keyUserName);
  }

  // ─── Generic ──────────────────────────────────────────────
  static T? get<T>(String key) => _box.read<T>(key);
  static Future<void> set<T>(String key, T value) => _box.write(key, value);
  static Future<void> remove(String key) => _box.remove(key);
  static Future<void> clearAll() => _box.erase();
}
