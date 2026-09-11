import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_constants.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import '../../core/widgets/custom_mobile_bottom_bar.dart';
import '../../core/widgets/animated_top_bar_title.dart';
import '../../core/widgets/two_step_logout_dialog.dart';
import '../../core/widgets/notification_center_drawer.dart';
import '../../core/services/notification_service.dart';
import '../auth/auth_service.dart';
import '../auth/widgets/forced_password_change_dialog.dart';
import 'dashboard/admin_dashboard_page.dart';
import 'director_calendar/admin_director_calendar_page.dart';
import 'therapists/admin_therapists_page.dart';
import 'students/admin_students_page.dart';
import 'stud_progress/admin_stud_progress_page.dart';
import 'iep_reports/admin_iep_reports_page.dart';
import 'settings/admin_settings_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ForcedPasswordChangeDialog.showIfNeeded(context);
      NotificationService().fetchNotifications();
    });
  }

  late final List<Widget> _pages = [
    AdminDashboardPage(
      onNavigateCalendar: () => setState(() => _selectedIndex = 1),
    ),
    const AdminDirectorCalendarPage(),
    const AdminTherapistsPage(),
    const AdminStudentsPage(),
    const AdminStudProgressPage(),
    const AdminIepReportsPage(),
    const AdminSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final sidebarWidget = Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Column(
        children: [
          // Logo Area
          InkWell(
            onTap: () {
              if (isMobile) Navigator.of(context).maybePop();
              setState(() => _selectedIndex = 0);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 84,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              child: AppImages.rohLogo(height: 38),
            ),
          ),
          _buildNavItem(0, 'Dashboard', Icons.home, isDrawer: isMobile),
          _buildNavItem(1, 'Director Calendar', Icons.event_available_outlined, isDrawer: isMobile),
          _buildNavItem(2, 'Therapist', Icons.volunteer_activism_outlined, isDrawer: isMobile),
          _buildNavItem(3, 'Students', Icons.person_outline, isDrawer: isMobile),
          _buildNavItem(4, 'Stud Progress', Icons.bar_chart, isDrawer: isMobile),
          _buildNavItem(5, 'IEP Reports', Icons.credit_card_outlined, isDrawer: isMobile),
          _buildNavItem(6, 'Settings', Icons.settings_outlined, isDrawer: isMobile),
        ],
      ),
    );

    final topBarWidget = Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: AppColors.primary),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          Expanded(
            child: AnimatedTopBarTitle(isMobile: isMobile),
          ),
          InkWell(
            onTap: () => NotificationCenterDrawer.show(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
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
          SizedBox(width: isMobile ? 8 : 16),
          PopupMenuButton<String>(
            tooltip: 'Profile & Portal Switcher',
            offset: const Offset(0, 48),
            onSelected: (value) async {
              if (value == 'logout') {
                final shouldLogout = await TwoStepLogoutDialog.show(context);
                if (shouldLogout == true && context.mounted) {
                  await context.read<AuthService>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed(AppConstants.routeLogin);
                  }
                }
              } else {
                Navigator.of(context).pushReplacementNamed(value);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                enabled: false,
                child: Text('Switch Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const PopupMenuItem(
                value: AppConstants.routeAdmin,
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Admin Panel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: AppConstants.routeTherapist,
                child: Row(
                  children: [
                    Icon(Icons.medical_services, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Therapist Panel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: AppConstants.routeParent,
                child: Row(
                  children: [
                    Icon(Icons.family_restroom, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Parent Panel'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: AppImages.therapistAvatar(radius: 18),
          ),
        ],
      ),
    );

    final contentWidget = IndexedStack(
      index: _selectedIndex,
      children: _pages,
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        drawer: Drawer(child: SafeArea(child: sidebarWidget)),
        body: SafeArea(
          child: Column(
            children: [
              topBarWidget,
              Expanded(child: contentWidget),
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
              icon: Icons.volunteer_activism_outlined,
              activeIcon: Icons.volunteer_activism,
              label: 'Therapist',
            ),
            CustomMobileBottomBarItem(
              icon: Icons.people_outline,
              activeIcon: Icons.people,
              label: 'Students',
            ),
            CustomMobileBottomBarItem(
              icon: Icons.trending_up,
              activeIcon: Icons.bar_chart,
              label: 'Stud Progress',
            ),
            CustomMobileBottomBarItem(
              icon: Icons.assignment_outlined,
              activeIcon: Icons.credit_card,
              label: 'IEP Reports',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Row(
        children: [
          sidebarWidget,
          Expanded(
            child: Column(
              children: [
                topBarWidget,
                Expanded(child: contentWidget),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, {bool isDrawer = false}) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (isDrawer) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sidebarSelectedBg : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textHint,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
