import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/data/models/post_model.dart';
import 'package:shirbrax/features/auth/controllers/auth_controller.dart';
import 'package:shirbrax/shared/widgets/app_button.dart';
import 'package:shirbrax/shared/widgets/app_text_field.dart';
import 'package:shirbrax/data/repositories/post_repository.dart';

class UploadView extends StatefulWidget {
  const UploadView({super.key});

  @override
  State<UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<UploadView> {
  final _captionCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  XFile? _selectedFile;
  bool _isVideo = false;
  bool _isUploading = false;
  PostVisibility _visibility = PostVisibility.public;

  final _picker = ImagePicker();

  /// Subscriber-only posts are available only once the author has switched
  /// subscriptions on and set a price (the API rejects it otherwise).
  bool get _canSellSubscription =>
      Get.find<AuthController>().user?.subscriptionEnabled ?? false;

  @override
  void dispose() {
    _captionCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() { _selectedFile = file; _isVideo = false; });
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file != null) setState(() { _selectedFile = file; _isVideo = true; });
  }

  Future<void> _upload() async {
    if (_selectedFile == null) {
      Get.snackbar('خطا', 'لطفاً یک عکس یا ویدیو انتخاب کنید',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _isUploading = true);
    try {
      final tags = _tagsCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final repo = PostRepository();
      await repo.createPost(
        caption: _captionCtrl.text.trim(),
        mediaType: _isVideo ? 'video' : 'photo',
        filePath: _selectedFile!.path,
        tags: tags,
        visibility: _visibility,
      );

      Get.snackbar('موفق', 'پست شما با موفقیت آپلود شد!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      Get.snackbar('خطا در آپلود', 'ارسال پست با خطا مواجه شد.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('پست جدید'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? width * 0.25 : 16,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Media picker ─────────────────────────
              _buildMediaPicker(),
              const SizedBox(height: 24),

              // ─── Caption ──────────────────────────────
              AppTextField(
                controller: _captionCtrl,
                label: 'توضیحات',
                hint: 'چیزی بنویس...',
                prefixIcon: Icons.edit_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // ─── Tags ─────────────────────────────────
              AppTextField(
                controller: _tagsCtrl,
                label: 'تگ‌ها (با کاما جدا کن)',
                hint: 'طبیعت, سفر, عکاسی',
                prefixIcon: Icons.tag_rounded,
              ),
              const SizedBox(height: 24),

              // ─── Who can see this post ────────────────
              _VisibilityPicker(
                value: _visibility,
                canSellSubscription: _canSellSubscription,
                onChanged: (v) => setState(() => _visibility = v),
              ),
              const SizedBox(height: 32),

              // ─── Upload button ────────────────────────
              AppButton(
                label: 'انتشار پست',
                isLoading: _isUploading,
                icon: Icons.cloud_upload_outlined,
                onPressed: _upload,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPicker() {
    return Column(
      children: [
        // Preview area
        GestureDetector(
          onTap: _pickImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 240,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedFile != null
                    ? AppColors.primary
                    : AppColors.border,
                width: _selectedFile != null ? 2 : 1,
              ),
            ),
            child: _selectedFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _isVideo
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.videocam_rounded,
                                    size: 56, color: AppColors.primary),
                                const SizedBox(height: 8),
                                Text('ویدیو انتخاب شد',
                                    style: AppTextStyles.titleSmall
                                        .copyWith(color: AppColors.primary)),
                                Text(_selectedFile!.name,
                                    style: AppTextStyles.labelSmall),
                              ],
                            ),
                          )
                        : Image.file(
                            File(_selectedFile!.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_photo_alternate_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text('انتخاب عکس',
                          style: AppTextStyles.titleSmall
                              .copyWith(color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text('برای انتخاب ضربه بزنید',
                          style: AppTextStyles.labelSmall),
                    ],
                  ),
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 12),

        // Type buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('عکس'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: !_isVideo && _selectedFile != null
                        ? AppColors.primary
                        : AppColors.border,
                    width: !_isVideo && _selectedFile != null ? 2 : 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.videocam_outlined, size: 18),
                label: const Text('ویدیو'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _isVideo && _selectedFile != null
                        ? AppColors.primary
                        : AppColors.border,
                    width: _isVideo && _selectedFile != null ? 2 : 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Chooses who may open the post being uploaded.
class _VisibilityPicker extends StatelessWidget {
  final PostVisibility value;
  final bool canSellSubscription;
  final ValueChanged<PostVisibility> onChanged;

  const _VisibilityPicker({
    required this.value,
    required this.canSellSubscription,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.visibility_outlined,
                size: 18, color: AppColors.mutedForeground),
            const SizedBox(width: 6),
            Text('چه کسی می‌تواند ببیند؟', style: AppTextStyles.labelMedium),
          ],
        ),
        const SizedBox(height: 8),
        _Option(
          title: 'همه',
          subtitle: 'هر کسی که به حساب شما دسترسی دارد',
          icon: Icons.public_rounded,
          selected: value == PostVisibility.public,
          onTap: () => onChanged(PostVisibility.public),
        ),
        _Option(
          title: 'دنبال‌کنندگان',
          subtitle: 'فقط کسانی که شما را دنبال می‌کنند',
          icon: Icons.people_alt_rounded,
          selected: value == PostVisibility.followers,
          onTap: () => onChanged(PostVisibility.followers),
        ),
        _Option(
          title: 'مشترکین',
          subtitle: canSellSubscription
              ? 'فقط کسانی که اشتراک شما را خریده‌اند'
              : 'ابتدا اشتراک را در تنظیمات فعال کنید',
          icon: Icons.workspace_premium_rounded,
          selected: value == PostVisibility.subscribers,
          enabled: canSellSubscription,
          accent: AppColors.warning,
          onTap: () => onChanged(PostVisibility.subscribers),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final Color? accent;
  final VoidCallback onTap;

  const _Option({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primary;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : AppColors.border,
                width: selected ? 2 : 1,
              ),
              color: selected ? color.withValues(alpha: 0.06) : null,
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: selected ? color : AppColors.mutedForeground),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.labelMedium),
                      Text(subtitle,
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.mutedForeground)),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_circle_rounded, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
