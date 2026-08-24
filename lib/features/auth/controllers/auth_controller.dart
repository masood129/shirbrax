import 'package:get/get.dart';
import 'package:shirbrax/data/models/user_model.dart';
import 'package:shirbrax/data/repositories/auth_repository.dart';
import 'package:shirbrax/app/routes/app_routes.dart';
import 'package:shirbrax/app/routes/app_pages.dart';

class AuthController extends GetxController {
  final _repo = AuthRepository();

  // ─── State ────────────────────────────────────────────────
  final _user = Rxn<UserModel>();
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;

  // ─── Form field errors ────────────────────────────────────
  final _emailError = ''.obs;
  final _passwordError = ''.obs;
  final _nameError = ''.obs;
  final _usernameError = ''.obs;

  // ─── Getters ──────────────────────────────────────────────
  UserModel? get user => _user.value;
  bool get isLoggedIn => _user.value != null;
  bool get isAdmin => _user.value?.isAdmin ?? false;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  String get emailError => _emailError.value;
  String get passwordError => _passwordError.value;
  String get nameError => _nameError.value;
  String get usernameError => _usernameError.value;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUser();
  }

  // ─── Load saved user ──────────────────────────────────────
  Future<void> reloadUser() => _loadCurrentUser();

  void setUser(UserModel user) => _user.value = user;

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _repo.getMe();
      _user.value = user;
    } catch (_) {
      // Not logged in or token expired
    }
  }

  // ─── Login ────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    _clearErrors();
    if (!_validateLogin(email, password)) return;

    _isLoading.value = true;
    try {
      final user = await _repo.login(email: email, password: password);
      _user.value = user;
      AppPages.router.go(user.isAdmin ? AppRoutes.adminDashboard : AppRoutes.home);
    } catch (e) {
      _errorMessage.value = 'ایمیل یا رمز عبور اشتباه است.';
    } finally {
      _isLoading.value = false;
    }
  }

  // ─── Register ─────────────────────────────────────────────
  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    _clearErrors();
    if (!_validateRegister(name, username, email, password)) return;

    _isLoading.value = true;
    try {
      final user = await _repo.register(
        name: name,
        username: username,
        email: email,
        password: password,
      );
      _user.value = user;
      AppPages.router.go(AppRoutes.home);
    } catch (e) {
      _errorMessage.value = 'ثبت‌نام با خطا مواجه شد. دوباره تلاش کنید.';
    } finally {
      _isLoading.value = false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────
  Future<void> logout() async {
    await _repo.logout();
    _user.value = null;
    AppPages.router.go(AppRoutes.login);
  }

  // ─── Mock login (for testing without backend) ─────────────
  void mockLogin({bool asAdmin = false}) {
    _user.value = asAdmin ? UserModel.mockAdmin : UserModel.mockUser;
    AppPages.router.go(asAdmin ? AppRoutes.adminDashboard : AppRoutes.home);
  }

  // ─── Validation ───────────────────────────────────────────
  bool _validateLogin(String email, String password) {
    bool valid = true;
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      _emailError.value = 'ایمیل معتبر وارد کنید';
      valid = false;
    }
    if (password.length < 6) {
      _passwordError.value = 'رمز عبور باید حداقل ۶ کاراکتر باشد';
      valid = false;
    }
    return valid;
  }

  bool _validateRegister(
      String name, String username, String email, String password) {
    bool valid = true;
    if (name.trim().length < 2) {
      _nameError.value = 'نام باید حداقل ۲ کاراکتر باشد';
      valid = false;
    }
    if (username.trim().length < 3) {
      _usernameError.value = 'نام کاربری باید حداقل ۳ کاراکتر باشد';
      valid = false;
    }
    if (!GetUtils.isEmail(email)) {
      _emailError.value = 'ایمیل معتبر وارد کنید';
      valid = false;
    }
    if (password.length < 6) {
      _passwordError.value = 'رمز عبور باید حداقل ۶ کاراکتر باشد';
      valid = false;
    }
    return valid;
  }

  void _clearErrors() {
    _errorMessage.value = '';
    _emailError.value = '';
    _passwordError.value = '';
    _nameError.value = '';
    _usernameError.value = '';
  }
}
