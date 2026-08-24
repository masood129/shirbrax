import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/app/routes/app_routes.dart';
import 'package:shirbrax/features/auth/controllers/auth_controller.dart';
import 'package:shirbrax/data/models/user_model.dart';
import 'package:shirbrax/data/repositories/admin_repository.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final _adminRepo = AdminRepository();
  Map<String, dynamic>? _stats;
  List<UserModel> _recentUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _adminRepo.getStats();
      final users = await _adminRepo.getUsers();
      if (mounted) {
        setState(() {
          _stats = stats;
          _recentUsers = users.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _stats = {
            'users_count': 5,
            'posts_count': 5,
            'videos_count': 1,
            'likes_count': 9,
          };
          _recentUsers = [UserModel.mockUser];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('داشبورد مدیریت'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDashboard,
            tooltip: 'تازه‌سازی',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: auth.logout,
            tooltip: 'خروج',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isWide ? 32 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Welcome ────────────────────────────────
                    Text('سلام، ${auth.user?.name ?? 'مدیر'} 👋',
                        style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 4),
                    Text('خلاصه وضعیت سیستم',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.mutedForeground)),
                    const SizedBox(height: 24),

                    // ─── Stats cards ─────────────────────────────
                    GridView.count(
                      crossAxisCount: isWide ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _StatCard(
                          icon: Icons.people_rounded,
                          label: 'کاربران',
                          value: '${_stats?['users_count'] ?? 0}',
                          color: AppColors.accent,
                        ),
                        _StatCard(
                          icon: Icons.photo_library_rounded,
                          label: 'پست‌ها',
                          value: '${_stats?['posts_count'] ?? 0}',
                          color: AppColors.primary,
                        ),
                        _StatCard(
                          icon: Icons.videocam_rounded,
                          label: 'ویدیوها',
                          value: '${_stats?['videos_count'] ?? 0}',
                          color: AppColors.secondary,
                        ),
                        _StatCard(
                          icon: Icons.favorite_rounded,
                          label: 'لایک‌ها',
                          value: '${_stats?['likes_count'] ?? 0}',
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ─── Quick nav ───────────────────────────────
                    Text('دسترسی سریع', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickCard(
                            icon: Icons.people_rounded,
                            label: 'مدیریت کاربران',
                            onTap: () => context.go(AppRoutes.adminUsers),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickCard(
                            icon: Icons.photo_library_rounded,
                            label: 'مدیریت پست‌ها',
                            onTap: () => context.go(AppRoutes.adminPosts),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ─── Recent users ────────────────────────────
                    Text('آخرین کاربران', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 12),
                    ..._recentUsers.map((u) => _UserTile(user: u)),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: AppTextStyles.headlineSmall
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(label,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.mutedForeground)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 32),
              const SizedBox(height: 8),
              Text(label,
                  style: AppTextStyles.titleSmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Text(user.name.isNotEmpty ? user.name.substring(0, 1) : 'U',
              style:
                  AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
        ),
        title: Text(user.name, style: AppTextStyles.titleSmall),
        subtitle: Text('@${user.username}', style: AppTextStyles.labelSmall),
        trailing: Chip(
          label: Text(user.isAdmin ? 'ادمین' : 'کاربر',
              style: AppTextStyles.labelSmall.copyWith(
                  color:
                      user.isAdmin ? AppColors.accent : AppColors.mutedForeground)),
          backgroundColor: user.isAdmin
              ? AppColors.accentContainer
              : AppColors.muted,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
