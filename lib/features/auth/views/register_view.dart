import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';

import '../controllers/auth_controller.dart';

import 'package:shirbrax/shared/widgets/app_button.dart';
import 'package:shirbrax/shared/widgets/app_text_field.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  final _auth = Get.find<AuthController>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? size.width * 0.3 : 24,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  'ایجاد حساب کاربری',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ).animate().fadeIn().slideY(begin: 0.2),
                const SizedBox(height: 8),
                Text(
                  'اطلاعات خود را وارد کنید',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 32),

                // Form
                Obx(
                  () => Column(
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

                      AppTextField(
                        controller: _nameCtrl,
                        label: 'نام و نام‌خانوادگی',
                        hint: 'مثلاً: علی محمدی',
                        prefixIcon: Icons.person_outline_rounded,
                        errorText: _auth.nameError.isNotEmpty
                            ? _auth.nameError
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _usernameCtrl,
                        label: 'نام کاربری',
                        hint: 'مثلاً: ali_m',
                        prefixIcon: Icons.alternate_email_rounded,
                        errorText: _auth.usernameError.isNotEmpty
                            ? _auth.usernameError
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'ایمیل',
                        hint: 'example@email.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _auth.emailError.isNotEmpty
                            ? _auth.emailError
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _passwordCtrl,
                        label: 'رمز عبور',
                        hint: 'حداقل ۶ کاراکتر',
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
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'ثبت‌نام',
                        isLoading: _auth.isLoading,
                        onPressed: () => _auth.register(
                          name: _nameCtrl.text,
                          username: _usernameCtrl.text,
                          email: _emailCtrl.text,
                          password: _passwordCtrl.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
