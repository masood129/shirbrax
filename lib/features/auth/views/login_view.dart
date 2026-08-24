import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/app/routes/app_routes.dart';

import '../controllers/auth_controller.dart';

import 'package:shirbrax/shared/widgets/app_button.dart';
import 'package:shirbrax/shared/widgets/app_text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  final _auth = Get.find<AuthController>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? size.width * 0.3 : 24,
              vertical: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Logo & Title ───────────────────────────
                _buildHeader(),
                const SizedBox(height: 48),

                // ─── Form ───────────────────────────────────
                _buildForm(),
                const SizedBox(height: 32),

                // ─── Action Buttons ─────────────────────────
                _buildActions(),
                const SizedBox(height: 24),

                // ─── Register link ──────────────────────────
                _buildRegisterLink(),

                // ─── Dev: Mock login ────────────────────────
                const SizedBox(height: 32),
                _buildDevButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.photo_library_rounded,
                color: Colors.white,
                size: 40,
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 20),
        Text(
          'شیربرکس',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
        const SizedBox(height: 8),
        Text(
          'لحظه‌های خاص را با دوستان صمیمیت به اشتراک بگذار',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildForm() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error banner
          if (_auth.errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _auth.errorMessage,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().shakeX(),

          // Email
          AppTextField(
            controller: _emailCtrl,
            label: 'ایمیل',
            hint: 'example@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            errorText: _auth.emailError.isNotEmpty ? _auth.emailError : null,
          ),
          const SizedBox(height: 16),

          // Password
          AppTextField(
            controller: _passwordCtrl,
            label: 'رمز عبور',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            errorText: _auth.passwordError.isNotEmpty
                ? _auth.passwordError
                : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.mutedForeground,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: 8),

          // Forgot password
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'فراموشی رمز عبور؟',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Obx(
      () => AppButton(
        label: 'ورود',
        isLoading: _auth.isLoading,
        onPressed: () => _auth.login(_emailCtrl.text, _passwordCtrl.text),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'حساب کاربری ندارید؟',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
        TextButton(
          onPressed: () => Get.toNamed(AppRoutes.register),
          child: Text(
            'ثبت‌نام کنید',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  /// Dev shortcut buttons — remove in production
  Widget _buildDevButtons() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'ورود آزمایشی (بدون بک‌اند)',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _auth.mockLogin(),
                icon: const Icon(Icons.person_outline, size: 16),
                label: const Text('ورود کاربر'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _auth.mockLogin(asAdmin: true),
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                label: const Text('ورود ادمین'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
