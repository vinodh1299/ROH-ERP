// lib/features/director/director_shell.dart
//
// Main shell for the Director section. Contains:
//   - Responsive sidebar (collapsible on mobile)
//   - Top app bar with user info + notification bell
//   - Page navigation for all Director sub-sections
//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_constants.dart';
import '../../core/widgets/custom_mobile_bottom_bar.dart';
import '../../core/widgets/animated_top_bar_title.dart';
import '../../core/widgets/two_step_logout_dialog.dart';
import '../../core/widgets/notification_center_drawer.dart';
import '../../core/services/notification_service.dart';
import '../auth/auth_service.dart';
import '../auth/widgets/forced_password_change_dialog.dart';
import 'approvals/director_password_resets_view.dart';
import 'dashboard/director_dashboard_page.dart';
import 'schedule_section/director_schedule_page.dart';
import 'therapist_section/therapist_section_page.dart';
import 'students_section/students_section_page.dart';
import 'stud_progress_section/stud_progress_section_page.dart';
import 'iep_reports_section/iep_reports_section_page.dart';
import 'settings_section/settings_section_page.dart';

class DirectorShell extends StatefulWidget {
  const DirectorShell({super.key});

  @override
  State<DirectorShell> createState() => _DirectorShellState();
}

class _DirectorShellState extends State<DirectorShell> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ForcedPasswordChangeDialog.showIfNeeded(context);
      NotificationService().fetchNotifications();
    });
  }

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Master Schedule'),
    _NavItem(icon: Icons.medical_services_outlined, activeIcon: Icons.medical_services, label: 'Therapist'),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Students'),
    _NavItem(icon: Icons.trending_up_outlined, activeIcon: Icons.trending_up, label: 'Stud Progress'),
    _NavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment, label: 'IEP Reports'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
  ];

  final List<Widget> _pages = const [
    DirectorDashboardPage(),
    DirectorSchedulePage(),
    TherapistSectionPage(),
    StudentsSectionPage(),
    StudProgressSectionPage(),
    IepReportsSectionPage(),
    SettingsSectionPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final isTablet = width >= 768 && width < 1100;

    // On mobile, use bottom nav bar or drawer
    if (isMobile) {
      return _buildMobileScaffold();
    }

    // On tablet/desktop use persistent sidebar
    final sidebarW = (isTablet || !_sidebarExpanded) ? 70.0 : 230.0;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: sidebarW,
            child: _Sidebar(
              items: _navItems,
              selectedIndex: _selectedIndex,
              expanded: _sidebarExpanded && !isTablet,
              onItemSelected: (i) => setState(() => _selectedIndex = i),
              onToggle: isTablet ? null : () => setState(() => _sidebarExpanded = !_sidebarExpanded),
            ),
          ),
          // ── Main content ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  title: _navItems[_selectedIndex].label,
                  onMenuTap: isMobile ? () {} : null,
                ),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileScaffold() {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      drawer: Drawer(
        child: SafeArea(
          child: _Sidebar(
            items: _navItems,
            selectedIndex: _selectedIndex,
            expanded: true,
            onItemSelected: (i) {
              setState(() => _selectedIndex = i);
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (ctx) => _TopBar(
                title: _navItems[_selectedIndex].label,
                onMenuTap: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: CustomMobileBottomBar(
        currentIndex: () {
          if (_selectedIndex == 0) return 0; // Dashboard
          if (_selectedIndex == 2) return 1; // Therapist
          if (_selectedIndex == 3) return 2; // Students
          if (_selectedIndex == 4) return 3; // Stud Progress
          if (_selectedIndex == 5) return 4; // IEP Reports
          return -1;
        }(),
        onTap: (index) {
          const mapping = [0, 2, 3, 4, 5];
          setState(() => _selectedIndex = mapping[index]);
        },
        items: const [
          CustomMobileBottomBarItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
          ),
          CustomMobileBottomBarItem(
            icon: Icons.medical_services_outlined,
            activeIcon: Icons.medical_services,
            label: 'Therapist',
          ),
          CustomMobileBottomBarItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: 'Students',
          ),
          CustomMobileBottomBarItem(
            icon: Icons.trending_up_outlined,
            activeIcon: Icons.trending_up,
            label: 'Stud Progress',
          ),
          CustomMobileBottomBarItem(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment,
            label: 'IEP Reports',
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ──────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final bool expanded;
  final ValueChanged<int> onItemSelected;
  final VoidCallback? onToggle;

  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.expanded,
    required this.onItemSelected,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              onItemSelected(0);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('ROH', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('ROH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    ),
                    if (onToggle != null)
                      IconButton(icon: const Icon(Icons.menu, size: 20), onPressed: onToggle, color: AppColors.textSecondary),
                  ] else if (onToggle != null)
                    IconButton(icon: const Icon(Icons.menu, size: 20), onPressed: onToggle, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),
          // ── Nav items ───────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final isSelected = i == selectedIndex;
                return Tooltip(
                  message: expanded ? '' : item.label,
                  child: InkWell(
                    onTap: () => onItemSelected(i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: EdgeInsets.symmetric(
                          horizontal: expanded ? 14 : 0, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.sidebarSelectedBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                        children: [
                          if (isSelected)
                            Container(
                              width: 3,
                              height: 18,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: 20,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                          if (expanded) ...[
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // ── Logout ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: () async {
                final shouldLogout = await TwoStepLogoutDialog.show(context);
                if (shouldLogout == true && context.mounted) {
                  await context.read<AuthService>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed(AppConstants.routeLogin);
                  }
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: expanded ? 14 : 0, vertical: 12),
                child: Row(
                  mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, size: 20, color: AppColors.textSecondary),
                    if (expanded) ...[
                      const SizedBox(width: 12),
                      const Text('Logout', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onMenuTap;

  const _TopBar({required this.title, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final user = context.watch<AuthService>().currentUser;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 20),
      color: Colors.white,
      child: Row(
        children: [
          if (onMenuTap != null)
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.primary),
              onPressed: onMenuTap,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          Expanded(
            child: AnimatedTopBarTitle(isMobile: isMobile),
          ),
          if (!isMobile) ...[
            TextButton.icon(
              onPressed: () => DirectorPasswordResetsView.show(context),
              icon: const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.primary),
              label: const Text('Reset Approvals', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            IconButton(
              tooltip: 'Reset Approvals',
              icon: const Icon(Icons.verified_user_outlined, size: 20, color: AppColors.primary),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              onPressed: () => DirectorPasswordResetsView.show(context),
            ),
            const SizedBox(width: 4),
          ],
          // Notification bell
          InkWell(
            onTap: () => NotificationCenterDrawer.show(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 20),
                  ListenableBuilder(
                    listenable: NotificationService(),
                    builder: (context, _) {
                      final count = NotificationService().unreadCount;
                      if (count <= 0) return const SizedBox.shrink();
                      return Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                          child: Text(
                            '$count',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'A',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav item model ────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
