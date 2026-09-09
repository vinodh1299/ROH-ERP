// lib/features/therapist/therapist_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../auth/auth_service.dart';
import 'dashboard/therapist_dashboard_page.dart';
import 'vb_assessment/vb_assessment_page.dart';
import 'vb_milestone/vb_milestone_page.dart';
import 'barriers_assessment/barriers_assessment_page.dart';
import 'transition_assessment/transition_assessment_page.dart';
import 'ees_assessment/ees_assessment_page.dart';
import 'reinforcers/reinforcer_page.dart';
import 'iep/iep_page.dart';
import 'daily_data_sheet/daily_data_sheet_page.dart';
import 'manding_sheet/manding_sheet_page.dart';
import 'abc_data_sheet/abc_data_sheet_page.dart';
import 'brp/brp_page.dart';
import 'profile/profile_page.dart';

class TherapistShell extends StatefulWidget {
  const TherapistShell({super.key});

  @override
  State<TherapistShell> createState() => _TherapistShellState();
}

class _TherapistShellState extends State<TherapistShell> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;
  bool _vbAssessmentExpanded = true; // Dropdown toggle state matching Figma media_1788948308194.png

  final List<Widget> _pages = const [
    TherapistDashboardPage(),
    VbAssessmentPage(),
    VbMilestonePage(),
    BarriersAssessmentPage(),
    TransitionAssessmentPage(),
    EesAssessmentPage(),
    ReinforcerPage(),
    TherapistIepPage(),
    DailyDataSheetPage(),
    MandingSheetPage(),
    AbcDataSheetPage(),
    BrpPage(),
    TherapistProfilePage(),
  ];

  final List<String> _pageTitles = const [
    'Dashboard',
    'VB Assessment Overview',
    'Milestone Assessment',
    'Barriers Assessment',
    'Transition Assessment',
    'EES Echoic Assessment',
    'Preference Assessment',
    'IEP & Reports',
    'Daily Data Sheet',
    'Manding Sheet',
    'ABC Data Sheet',
    'BRP Interventions',
    'Therapist Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final isTablet = width >= 768 && width < 1100;

    if (isMobile) return _buildMobileScaffold();

    final sidebarW = (isTablet || !_sidebarExpanded) ? 70.0 : 240.0;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: sidebarW,
            child: _Sidebar(
              selectedIndex: _selectedIndex,
              expanded: _sidebarExpanded && !isTablet,
              vbExpanded: _vbAssessmentExpanded,
              onToggleVb: () => setState(() => _vbAssessmentExpanded = !_vbAssessmentExpanded),
              onItemSelected: (i) => setState(() => _selectedIndex = i),
              onToggleSidebar: isTablet ? null : () => setState(() => _sidebarExpanded = !_sidebarExpanded),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: _pageTitles[_selectedIndex]),
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
        child: _TopBar(title: _pageTitles[_selectedIndex]),
      ),
      drawer: Drawer(
        child: _Sidebar(
          selectedIndex: _selectedIndex,
          expanded: true,
          vbExpanded: _vbAssessmentExpanded,
          onToggleVb: () => setState(() => _vbAssessmentExpanded = !_vbAssessmentExpanded),
          onItemSelected: (i) {
            setState(() => _selectedIndex = i);
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

// ── Custom Expandable Sidebar matching Figma media_1788948308194.png ──────────
class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final bool expanded;
  final bool vbExpanded;
  final VoidCallback? onToggleVb;
  final ValueChanged<int> onItemSelected;
  final VoidCallback? onToggleSidebar;

  const _Sidebar({
    required this.selectedIndex,
    required this.expanded,
    required this.vbExpanded,
    this.onToggleVb,
    required this.onItemSelected,
    this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Logo Header
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
                    child: Text('ROH', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('ROH Therapist', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ),
                  if (onToggleSidebar != null)
                    IconButton(icon: const Icon(Icons.menu, size: 20), onPressed: onToggleSidebar, color: AppColors.textSecondary),
                ] else if (onToggleSidebar != null)
                  IconButton(icon: const Icon(Icons.menu, size: 20), onPressed: onToggleSidebar, color: AppColors.textSecondary),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                // 1. Dashboard
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),

                // 2. VB Assessment Dropdown Parent (Matching Figma Frame media_1788948308194.png)
                InkWell(
                  onTap: () {
                    onItemSelected(1);
                    if (onToggleVb != null) onToggleVb!();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 0, vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedIndex == 1 ? AppColors.sidebarSelectedBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.assessment_outlined, size: 20, color: AppColors.primary),
                        if (expanded) ...[
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'VB Assessment',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          Icon(
                            vbExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Sub-Items under VB Assessment (Indented matching Figma)
                if (vbExpanded && expanded) ...[
                  _buildSubNavItem(2, 'Milestone Assessment'),
                  _buildSubNavItem(3, 'Barriers Assessment'),
                  _buildSubNavItem(4, 'Transition Assessment'),
                  _buildSubNavItem(5, 'EES Assessment'),
                  _buildSubNavItem(6, 'Preference Assessment'),
                ],

                const SizedBox(height: 6),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 6),

                // Remaining Modules
                _buildNavItem(7, Icons.bar_chart_outlined, Icons.bar_chart, 'IEP & Reports'),
                _buildNavItem(8, Icons.table_chart_outlined, Icons.table_chart, 'Daily Data Sheet'),
                _buildNavItem(9, Icons.equalizer_outlined, Icons.equalizer, 'Manding Sheet'),
                _buildNavItem(10, Icons.receipt_long_outlined, Icons.receipt_long, 'ABC Data Sheet'),
                _buildNavItem(11, Icons.shield_outlined, Icons.shield, 'BRP Interventions'),
                _buildNavItem(12, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
          // Logout
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: () async {
                await context.read<AuthService>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed(AppConstants.routeLogin);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 0, vertical: 12),
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

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = selectedIndex == index;
    return Tooltip(
      message: expanded ? '' : label,
      child: InkWell(
        onTap: () => onItemSelected(index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 0, vertical: 12),
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
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
                ),
              Icon(isSelected ? activeIcon : icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              if (expanded) ...[
                const SizedBox(width: 12),
                Text(
                  label,
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
  }

  Widget _buildSubNavItem(int index, String label) {
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onItemSelected(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(left: 24, bottom: 2, top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.arrow_right : Icons.circle_outlined,
              size: 14,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.85),
                ),
              ),
            ),
          ],
        ),
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
              '${AppConstants.centerName.toUpperCase()} — $title',
              style: const TextStyle(
                fontSize: 13,
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
                const Icon(Icons.notifications_none_outlined, size: 22, color: AppColors.textSecondary),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'T',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
