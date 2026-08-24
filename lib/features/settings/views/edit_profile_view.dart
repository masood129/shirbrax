import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/data/repositories/user_repository.dart';
import 'package:shirbrax/features/auth/controllers/auth_controller.dart';
import 'package:shirbrax/shared/widgets/app_button.dart';
import 'package:shirbrax/shared/widgets/app_text_field.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  final _userRepo = UserRepository();
  final _picker = ImagePicker();
  XFile? _selectedAvatar;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = Get.find<AuthController>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedAvatar = image);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await _userRepo.updateProfile(
        name: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        avatarFilePath: _selectedAvatar?.path,
      );

      // Update in AuthController
      final auth = Get.find<AuthController>();
      auth.setUser(updated);

      Get.snackbar('موفق', 'پروفایل به‌روزرسانی شد',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      Get.snackbar('خطا', 'ویرایش پروفایل با خطا مواجه شد.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ویرایش پروفایل'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('ذخیره',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? width * 0.2 : 20,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ─── Avatar ───────────────────────────────────────
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        _nameCtrl.text.isNotEmpty
                            ? _nameCtrl.text[0]
                            : 'U',
                        style: AppTextStyles.displaySmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ).animate().scale(),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _pickAvatar,
                child: Text('تغییر عکس پروفایل',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.primary)),
              ),
              const SizedBox(height: 24),

              // ─── Fields ───────────────────────────────────────
              AppTextField(
                controller: _nameCtrl,
                label: 'نام و نام‌خانوادگی',
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _usernameCtrl,
                label: 'نام کاربری',
                prefixIcon: Icons.alternate_email_rounded,
                hint: 'مثال: ali_m',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _bioCtrl,
                label: 'بیوگرافی',
                prefixIcon: Icons.edit_note_rounded,
                hint: 'کمی درباره خودت بنویس...',
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'ذخیره تغییرات',
                isLoading: _saving,
                onPressed: _save,
                icon: Icons.save_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
