import '../../core/storage/local_storage.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class AuthRepository {
  final _provider = AuthProvider();

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final data = await _provider.login(email: email, password: password);
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await LocalStorage.saveAuthData(
      token: token,
      role: user.role,
      userId: user.id,
      userName: user.name,
    );

    return user;
  }

  Future<UserModel> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final data = await _provider.register(
      name: name,
      username: username,
      email: email,
      password: password,
    );
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await LocalStorage.saveAuthData(
      token: token,
      role: user.role,
      userId: user.id,
      userName: user.name,
    );

    return user;
  }

  Future<void> logout() async {
    try {
      await _provider.logout();
    } finally {
      await LocalStorage.clearAuth();
    }
  }

  Future<UserModel?> getMe() async {
    if (!LocalStorage.isLoggedIn) return null;
    return _provider.getMe();
  }
}
