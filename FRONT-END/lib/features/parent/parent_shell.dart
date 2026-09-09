// lib/features/parent/parent_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../auth/auth_service.dart';
import 'dashboard/parent_dashboard_page.dart';
import 'progress_reports/progress_reports_page.dart';
import 'iep_goal_data/iep_goal_data_page.dart';
import 'graphs/graphs_page.dart';
import 'profile/profile_page.dart';

import 'test_complete/test_complete_page.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_outlined,   activeIcon: Icons.dashboard,    label: 'Dashboard'),
    _NavItem(icon: Icons.check_circle_outline, activeIcon: Icons.check_circle, label: 'Test Complete'),
    _NavItem(icon: Icons.bar_chart_outlined,   activeIcon: Icons.bar_chart,    label: 'Progress Reports'),
    _NavItem(icon: Icons.person_outline,       activeIcon: Icons.person,       label: 'IEP Goal Data'),
    _NavItem(icon: Icons.show_chart_outlined,  activeIcon: Icons.show_chart,   label: 'Graphs'),
    _NavItem(icon: Icons.settings_outlined,    activeIcon: Icons.settings,     label: 'Profile'),
  ];

  final List<Widget> _pages = const [
    ParentDashboardPage(),
    ParentTestCompletePage(),
    ProgressReportsPage(),
    IepGoalDataPage(),
    GraphsPage(),
    ParentProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final isTablet = width >= 768 && width < 1100;

    if (isMobile) return _buildMobileScaffold();

    final sidebarW = (isTablet || !_sidebarExpanded) ? 70.0 : 230.0;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: sidebarW,
            child: _Sidebar(
              items: _navItems,
              selectedIndex: _selectedIndex,
              expanded: _sidebarExpanded && !isTablet,
              onItemSelected: (i) => setState(() => _selectedIndex = i),
              onToggle: isTablet
                  ? null
                  : () => setState(() => _sidebarExpanded = !_sidebarExpanded),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: _navItems[_selectedIndex].label),
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _TopBar(title: _navItems[_selectedIndex].label),
      ),
      drawer: Drawer(
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        destinations: _navItems.map((item) => NavigationDestination(
          icon: Icon(item.icon, size: 22),
          selectedIcon: Icon(item.activeIcon, color: AppColors.primary, size: 22),
          label: item.label,
        )).toList(),
      ),
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────
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
          // Logo
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.welcomeGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('ROH',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('ROH',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                  ),
                  if (onToggle != null)
                    IconButton(
                      icon: const Icon(Icons.menu, size: 20),
                      onPressed: onToggle,
                      color: AppColors.textSecondary,
                    ),
                ] else if (onToggle != null)
                  IconButton(
                    icon: const Icon(Icons.menu, size: 20),
                    onPressed: onToggle,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),
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
                        color: isSelected
                            ? AppColors.sidebarSelectedBg
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: expanded
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
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
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          if (expanded) ...[
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                item.label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
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
          // Logout
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: () async {
                await context.read<AuthService>().logout();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushReplacementNamed(AppConstants.routeLogin);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: expanded ? 14 : 0, vertical: 12),
                child: Row(
                  mainAxisAlignment: expanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout,
                        size: 20, color: AppColors.textSecondary),
                    if (expanded) ...[
                      const SizedBox(width: 12),
                      const Text('Logout',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
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

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppConstants.centerName.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_outlined,
                    size: 22, color: AppColors.textSecondary),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
              user?.name.isNotEmpty == true
                  ? user!.name[0].toUpperCase()
                  : 'P',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
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
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}
