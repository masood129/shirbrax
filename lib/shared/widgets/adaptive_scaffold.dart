import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shirbrax/app/theme/app_colors.dart';
import 'package:shirbrax/app/theme/app_text_styles.dart';
import 'package:shirbrax/app/routes/app_routes.dart';
import 'package:shirbrax/core/utils/responsive_helper.dart';
import 'package:shirbrax/features/auth/controllers/auth_controller.dart';
import 'package:shirbrax/shared/controllers/theme_controller.dart';

/// Adaptive scaffold — BottomNav on mobile, NavigationRail on web/tablet
class AdaptiveScaffold extends StatefulWidget {
  final Widget child;
  final bool isAdmin;

  const AdaptiveScaffold({
    super.key,
    required this.child,
    this.isAdmin = false,
  });

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  AuthController get _auth => Get.find<AuthController>();
  ThemeController get _theme => Get.find<ThemeController>();

  List<_NavItem> get _userNavItems => [
        _NavItem(Icons.home_rounded, Icons.home_outlined, 'خانه', AppRoutes.home),
        _NavItem(Icons.explore_rounded, Icons.explore_outlined, 'کاوش', AppRoutes.explore),
        _NavItem(Icons.add_circle_rounded, Icons.add_circle_outline_rounded, 'آپلود', AppRoutes.upload),
        _NavItem(Icons.notifications_rounded, Icons.notifications_outlined, 'اعلان', AppRoutes.notifications),
        _NavItem(Icons.person_rounded, Icons.person_outline_rounded, 'پروفایل',
            AppRoutes.profilePath(_auth.user?.id ?? '1')),
      ];

  List<_NavItem> get _adminNavItems => [
        _NavItem(Icons.dashboard_rounded, Icons.dashboard_outlined, 'داشبورد', AppRoutes.adminDashboard),
        _NavItem(Icons.people_rounded, Icons.people_outline_rounded, 'کاربران', AppRoutes.adminUsers),
        _NavItem(Icons.photo_library_rounded, Icons.photo_library_outlined, 'پست‌ها', AppRoutes.adminPosts),
        _NavItem(Icons.settings_rounded, Icons.settings_outlined, 'تنظیمات', AppRoutes.settings),
      ];

  List<_NavItem> get navItems =>
      widget.isAdmin ? _adminNavItems : _userNavItems;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = navItems.indexWhere(
        (item) => location == item.route || location.startsWith('${item.route}/'));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ResponsiveHelper.showSideNav(width)
        ? _buildWebLayout(context)
        : _buildMobileLayout(context);
  }

  // ─── Mobile layout ──────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      body: widget.child,
      floatingActionButton: !widget.isAdmin
          ? FloatingActionButton(
              onPressed: () => context.go(AppRoutes.upload),
              tooltip: 'پست جدید',
              child: const Icon(Icons.add_rounded),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.surface,
        elevation: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: navItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final selected = i == idx;
            // Skip upload slot (handled by FAB)
            if (!widget.isAdmin && item.route == AppRoutes.upload) {
              return const SizedBox(width: 48);
            }
            return _BottomNavButton(
              item: item,
              selected: selected,
              onTap: () => context.go(item.route),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Web/Desktop layout ─────────────────────────────────────
  Widget _buildWebLayout(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final idx = _currentIndex(context);
    final extended = width > 1100;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: idx,
            onDestinationSelected: (i) => context.go(navItems[i].route),
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: _buildSideHeader(extended),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildSideTrailing(extended),
              ),
            ),
            destinations: navItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.iconOutlined),
                      selectedIcon: Icon(item.iconFilled),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildSideHeader(bool extended) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: extended
          ? Row(
              children: [
                _logo(),
                const SizedBox(width: 10),
                Text('شیربرکس',
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.primary)),
              ],
            )
          : _logo(),
    );
  }

  Widget _logo() => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.photo_library_rounded,
            color: Colors.white, size: 20),
      );

  Widget _buildSideTrailing(bool extended) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => IconButton(
                icon: Icon(_theme.isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded),
                onPressed: _theme.toggle,
                tooltip: _theme.isDark ? 'حالت روشن' : 'حالت تاریک',
              )),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _auth.logout,
            tooltip: 'خروج',
            color: AppColors.mutedForeground,
          ),
        ],
      ),
    );
  }
}

// ─── Helper classes ──────────────────────────────────────────
class _NavItem {
  final IconData iconFilled;
  final IconData iconOutlined;
  final String label;
  final String route;
  const _NavItem(this.iconFilled, this.iconOutlined, this.label, this.route);
}

class _BottomNavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? item.iconFilled : item.iconOutlined,
              color:
                  selected ? AppColors.primary : AppColors.mutedForeground,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? AppColors.primary : AppColors.mutedForeground,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
