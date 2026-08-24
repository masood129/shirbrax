import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/app/routes/app_routes.dart';
import 'package:shirbrax/features/auth/controllers/auth_controller.dart';
import 'package:shirbrax/shared/controllers/theme_controller.dart';
import 'package:shirbrax/shared/widgets/app_button.dart';
import 'package:shirbrax/shared/widgets/app_text_field.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final theme = Get.find<ThemeController>();
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 640 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Profile Card ──────────────────────────────────
              _SectionCard(
                children: [
                  Obx(() => ListTile(
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            auth.user?.name.substring(0, 1) ?? 'U',
                            style: AppTextStyles.headlineSmall
                                .copyWith(color: AppColors.primary),
                          ),
                        ),
                        title: Text(
                          auth.user?.name ?? '',
                          style: AppTextStyles.titleMedium,
                        ),
                        subtitle: Text(
                          '@${auth.user?.username ?? ''}',
                          style: AppTextStyles.labelSmall,
                        ),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: () => context.go(AppRoutes.editProfile),
                      )),
                ],
              ).animate().fadeIn(),

              const SizedBox(height: 16),

              // ─── Appearance ────────────────────────────────────
              _SectionTitle(title: 'ظاهر'),
              _SectionCard(
                children: [
                  Obx(() => SwitchListTile(
                        value: theme.isDark,
                        onChanged: (_) => theme.toggle(),
                        title: Text('حالت تاریک', style: AppTextStyles.bodyMedium),
                        secondary: Icon(
                          theme.isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: AppColors.primary,
                        ),
                  activeThumbColor: AppColors.primary,
                      )),
                ],
              ).animate().fadeIn(delay: 80.ms),

              const SizedBox(height: 16),

              // ─── Account ───────────────────────────────────────
              _SectionTitle(title: 'حساب کاربری'),
              _SectionCard(
                children: [
                  _SettingsTile(
                    icon: Icons.edit_outlined,
                    label: 'ویرایش پروفایل',
                    onTap: () => context.go(AppRoutes.editProfile),
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'تغییر رمز عبور',
                    onTap: () => _showChangePassword(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    label: 'تنظیمات اعلان',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56),
                  Obx(() {
                    final pending = auth.user?.pendingRequestsCount ?? 0;
                    return ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined,
                          color: AppColors.primary, size: 22),
                      title: Text('دسترسی و حریم خصوصی',
                          style: AppTextStyles.bodyMedium),
                      subtitle: Text(
                        auth.user?.isPrivate == true
                            ? 'حساب خصوصی'
                            : 'حساب عمومی',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.mutedForeground),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (pending > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(999)),
                              ),
                              child: Text('$pending',
                                  style: AppTextStyles.labelSmall
                                      .copyWith(color: Colors.white)),
                            ),
                          const Icon(Icons.chevron_left_rounded, size: 20),
                        ],
                      ),
                      onTap: () => context.go(AppRoutes.accessSettings),
                    );
                  }),
                ],
              ).animate().fadeIn(delay: 120.ms),

              const SizedBox(height: 16),

              // ─── About ─────────────────────────────────────────
              _SectionTitle(title: 'درباره برنامه'),
              _SectionCard(
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    label: 'نسخه ۱.۰.۰',
                    onTap: () {},
                    showArrow: false,
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    label: 'قوانین و مقررات',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.support_agent_outlined,
                    label: 'تماس با پشتیبانی',
                    onTap: () {},
                  ),
                ],
              ).animate().fadeIn(delay: 160.ms),

              const SizedBox(height: 24),

              // ─── Logout ─────────────────────────────────────────
              AppButton(
                label: 'خروج از حساب',
                icon: Icons.logout_rounded,
                onPressed: auth.logout,
                outlined: true,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تغییر رمز عبور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: oldPass,
              label: 'رمز عبور فعلی',
              obscureText: true,
              prefixIcon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: newPass,
              label: 'رمز عبور جدید',
              obscureText: true,
              prefixIcon: Icons.lock_reset_rounded,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Get.snackbar('موفق', 'رمز عبور تغییر یافت',
                  snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(title,
          style: AppTextStyles.labelMedium
              .copyWith(color: AppColors.mutedForeground)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(child: Column(children: children));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showArrow;
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing:
          showArrow ? const Icon(Icons.chevron_left_rounded, size: 20) : null,
      onTap: onTap,
    );
  }
}
