import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_constants.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import '../../core/widgets/custom_mobile_bottom_bar.dart';
import '../auth/auth_service.dart';
import 'dashboard/parent_dashboard_page.dart';
import 'progress_reports/progress_reports_page.dart';
import 'iep_goal_data/iep_goal_data_page.dart';
import 'graphs/graphs_page.dart';
import 'profile/profile_page.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    ParentDashboardPage(
      onNavigateTab: (index) => setState(() => _selectedIndex = index),
    ),
    const ProgressReportsPage(),
    const IepGoalDataPage(),
    const GraphsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final sidebarWidget = Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // ROH logo area
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
          const SizedBox(height: 16),
          _buildNavItem(0, 'Dashboard', Icons.home_outlined, isDrawer: isMobile),
          _buildNavItem(1, 'Progress Reports', Icons.medical_services_outlined, isDrawer: isMobile),
          _buildNavItem(2, 'IEP Goal Data', Icons.person_outline, isDrawer: isMobile),
          _buildNavItem(3, 'Graphs', Icons.bar_chart_outlined, isDrawer: isMobile),
          _buildNavItem(4, 'Profile', Icons.settings_outlined, isDrawer: isMobile),
        ],
      ),
    );

    final topBarWidget = Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
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
            child: Center(
              child: Text(
                'RAY OF HOPE CENTER FOR AUTISM',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: isMobile ? 12 : 16,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 16),
          PopupMenuButton<String>(
            tooltip: 'Profile & Portal Switcher',
            offset: const Offset(0, 48),
            onSelected: (value) async {
              if (value == 'logout') {
                await context.read<AuthService>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed(AppConstants.routeLogin);
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
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.divider,
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
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
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
          items: const [
            CustomMobileBottomBarItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: 'Dashboard',
            ),
            CustomMobileBottomBarItem(
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment,
              label: 'Reports',
            ),
            CustomMobileBottomBarItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'IEP Goals',
            ),
            CustomMobileBottomBarItem(
              icon: Icons.bar_chart_outlined,
              activeIcon: Icons.bar_chart,
              label: 'Graphs',
            ),
            CustomMobileBottomBarItem(
              icon: Icons.account_circle_outlined,
              activeIcon: Icons.account_circle,
              label: 'Profile',
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
    final bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
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
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
