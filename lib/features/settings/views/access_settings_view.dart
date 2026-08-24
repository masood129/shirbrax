import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shirbrax/app/routes/app_routes.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/features/settings/controllers/access_settings_controller.dart';
import 'package:shirbrax/shared/widgets/app_text_field.dart';

/// Privacy and paid-subscription settings for the signed-in account.
class AccessSettingsView extends StatelessWidget {
  const AccessSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AccessSettingsController>();
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('دسترسی و حریم خصوصی')),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isWide ? 640 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Private account ────────────────────────────
              Card(
                child: Column(
                  children: [
                    Obx(() => SwitchListTile(
                          value: ctrl.isPrivate,
                          onChanged:
                              ctrl.isSaving ? null : (v) => ctrl.setPrivate(v),
                          title: Text('حساب خصوصی',
                              style: AppTextStyles.bodyMedium),
                          subtitle: Text(
                            ctrl.isPrivate
                                ? 'فقط دنبال‌کنندگان تأییدشده پست‌ها و استوری‌های شما را می‌بینند.'
                                : 'همه می‌توانند پست‌های عمومی شما را ببینند.',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.mutedForeground),
                          ),
                          secondary: Icon(
                            ctrl.isPrivate
                                ? Icons.lock_rounded
                                : Icons.lock_open_rounded,
                            color: AppColors.primary,
                          ),
                          activeThumbColor: AppColors.primary,
                        )),
                    const Divider(height: 1, indent: 56),
                    Obx(() => ListTile(
                          leading: const Icon(Icons.person_add_alt_1_rounded,
                              color: AppColors.primary, size: 22),
                          title: Text('درخواست‌های دنبال کردن',
                              style: AppTextStyles.bodyMedium),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (ctrl.pendingRequestsCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.rectangle,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(999)),
                                  ),
                                  child: Text('${ctrl.pendingRequestsCount}',
                                      style: AppTextStyles.labelSmall
                                          .copyWith(color: Colors.white)),
                                ),
                              const Icon(Icons.chevron_left_rounded, size: 20),
                            ],
                          ),
                          onTap: () => context.go(AppRoutes.followRequests),
                        )),
                  ],
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 16),

              // ─── Paid subscription ──────────────────────────
              Text('اشتراک پولی',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.mutedForeground)),
              const SizedBox(height: 8),
              const _SubscriptionCard().animate().fadeIn(delay: 80.ms),

              const SizedBox(height: 16),
              Obx(() => ctrl.error.isEmpty
                  ? const SizedBox.shrink()
                  : Text(ctrl.error,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.error))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subscription toggle plus its price field. Separate widget so typing in the
/// price does not rebuild the rest of the settings list.
class _SubscriptionCard extends StatefulWidget {
  const _SubscriptionCard();

  @override
  State<_SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<_SubscriptionCard> {
  final _ctrl = Get.find<AccessSettingsController>();
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(
      text: _ctrl.subscriptionPrice > 0 ? '${_ctrl.subscriptionPrice}' : '',
    );
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  int get _enteredPrice => int.tryParse(_priceCtrl.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Obx(() => SwitchListTile(
                value: _ctrl.subscriptionEnabled,
                onChanged: _ctrl.isSaving
                    ? null
                    : (v) => _ctrl.setSubscriptionEnabled(v,
                        price: _enteredPrice),
                title: Text('فروش اشتراک', style: AppTextStyles.bodyMedium),
                subtitle: Text(
                  'با فعال کردن این گزینه می‌توانید پست‌هایی منتشر کنید که فقط مشترکین ببینند.',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.mutedForeground),
                ),
                secondary: const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.warning),
                activeThumbColor: AppColors.warning,
              )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _priceCtrl,
                  label: 'قیمت ماهانه (تومان)',
                  hint: '۵۰۰۰۰',
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Obx(() => Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: _ctrl.isSaving
                            ? null
                            : () => _ctrl.setPrice(_enteredPrice),
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('ذخیره قیمت'),
                      ),
                    )),
                Text(
                  'پرداخت در این نسخه شبیه‌سازی شده است و درگاه واقعی متصل نیست.',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
