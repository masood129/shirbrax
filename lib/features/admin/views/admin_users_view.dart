import 'package:flutter/material.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/data/models/user_model.dart';
import 'package:shirbrax/data/repositories/admin_repository.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  final _adminRepo = AdminRepository();
  final _searchCtrl = TextEditingController();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _adminRepo.getUsers(search: _filter);
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _users = [UserModel.mockAdmin, UserModel.mockUser];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleBan(UserModel user, int index) async {
    final originalBanned = user.isBanned;
    setState(() {
      _users[index] = user.copyWith(isBanned: !originalBanned);
    });

    try {
      await _adminRepo.banUser(user.id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _users[index] = user.copyWith(isBanned: originalBanned);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مدیریت کاربران')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'جستجو کاربران...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filter = '';
                          _loadUsers();
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) {
                _filter = v.trim();
                _loadUsers();
              },
            ),
          ),

          // User count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('${_users.length} کاربر',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.mutedForeground)),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _users.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _AdminUserTile(
                        user: _users[i],
                        onBan: () => _toggleBan(_users[i], i),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AdminUserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onBan;
  const _AdminUserTile({required this.user, required this.onBan});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: user.isBanned
                  ? AppColors.muted
                  : AppColors.primaryContainer,
              child: Text(
                user.name.isNotEmpty ? user.name.substring(0, 1) : 'U',
                style: AppTextStyles.titleSmall.copyWith(
                    color: user.isBanned
                        ? AppColors.mutedForeground
                        : AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: AppTextStyles.titleSmall),
                  Text('@${user.username}',
                      style: AppTextStyles.labelSmall),
                  Row(
                    children: [
                      if (user.isAdmin)
                        const _Badge('ادمین', AppColors.accent),
                      if (user.isBanned)
                        const _Badge('مسدود', AppColors.error),
                    ],
                  ),
                ],
              ),
            ),
            if (!user.isAdmin)
              IconButton(
                icon: Icon(
                  user.isBanned
                      ? Icons.lock_open_rounded
                      : Icons.block_rounded,
                  color: user.isBanned ? AppColors.success : AppColors.error,
                ),
                tooltip: user.isBanned ? 'رفع مسدودیت' : 'مسدود کردن',
                onPressed: onBan,
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: AppTextStyles.labelSmall.copyWith(color: color)),
    );
  }
}
