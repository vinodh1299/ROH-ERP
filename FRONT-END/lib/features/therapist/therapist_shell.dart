import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_constants.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import '../../core/widgets/custom_mobile_bottom_bar.dart';
import '../auth/auth_service.dart';
import 'dashboard/therapist_dashboard_page.dart';
import 'timetable/therapist_timetable_page.dart';
import 'vb_assessment/milestone_assessment_page.dart';
import 'vb_assessment/barriers_assessment_page.dart';
import 'vb_assessment/transition_assessment_page.dart';
import 'vb_assessment/ees_assessment_page.dart';
import 'vb_assessment/preference_assessment_page.dart';
import 'vb_assessment/vb_mapp_report_page.dart';
import 'iep/iep_page.dart';
import 'daily_data_sheet/daily_data_sheet_page.dart';
import 'profile/profile_page.dart';

class TherapistShell extends StatefulWidget {
  const TherapistShell({super.key});

  @override
  State<TherapistShell> createState() => _TherapistShellState();
}

class _TherapistShellState extends State<TherapistShell> {
  int _selectedIndex = 0;
  bool _isVbAssessmentExpanded = true;

  late final List<Widget> _pages = [
    TherapistDashboardPage(onNavigateTab: _onItemTapped),
    TherapistTimetablePage(onNavigateTab: _onItemTapped),
    const MilestoneAssessmentPage(),
    const BarriersAssessmentPage(),
    const TransitionAssessmentPage(),
    const EesAssessmentPage(),
    const PreferenceAssessmentPage(),
    const VbMappReportPage(),
    const IepPage(),
    const DailyDataSheetPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleVbAssessment() {
    setState(() {
      _isVbAssessmentExpanded = !_isVbAssessmentExpanded;
    });
  }

  bool _isVbChildSelected() {
    return _selectedIndex >= 2 && _selectedIndex <= 6;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final sidebarWidget = Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE6EFF5), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Authentic Figma ROH Logo (Puzzle + Flame + "ROH" text)
          InkWell(
            onTap: () {
              if (isMobile) Navigator.of(context).maybePop();
              _onItemTapped(0);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 84,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 28),
              child: AppImages.rohLogo(height: 38),
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  index: 0,
                  title: 'Dashboard',
                  icon: Icons.home,
                  isDrawer: isMobile,
                ),
                _buildMenuItem(
                  index: 1,
                  title: 'Time Table',
                  icon: Icons.calendar_today_outlined,
                  isDrawer: isMobile,
                ),
                
                // VB Assessment - Expandable with 5 sub-items
                _buildExpandableMenuItem(isDrawer: isMobile),

                // VB Milestone / Report
                _buildMenuItem(
                  index: 7,
                  title: 'VB Milestone',
                  icon: Icons.person,
                  isDrawer: isMobile,
                ),
                
                _buildMenuItem(
                  index: 8,
                  title: 'IEP',
                  icon: Icons.bar_chart,
                  isDrawer: isMobile,
                ),
                _buildMenuItem(
                  index: 9,
                  title: 'Daily Data Sheet',
                  icon: Icons.credit_card,
                  isDrawer: isMobile,
                ),
                _buildMenuItem(
                  index: 10,
                  title: 'Profile',
                  icon: Icons.settings,
                  isDrawer: isMobile,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final topBarWidget = Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE6EFF5), width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 28),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFFAB47BC)),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          Expanded(
            child: Center(
              child: Text(
                'RAY OF HOPE CENTER FOR AUTISM',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isMobile ? 12 : 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: const Color(0xFFAB47BC),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Container(
            width: isMobile ? 36 : 40,
            height: isMobile ? 36 : 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F6FA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              color: Color(0xFFAB47BC),
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
            child: AppImages.therapistAvatar(radius: isMobile ? 16 : 20),
          ),
        ],
      ),
    );

    final contentWidget = Container(
      color: AppColors.scaffold,
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
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
            if (_selectedIndex == 1) return 1; // Timetable / Sessions
            if (_isVbChildSelected() || _selectedIndex == 7) return 2; // VB Assessment / Milestones
            if (_selectedIndex == 8) return 3; // IEP
            if (_selectedIndex == 9) return 4; // Daily Data Sheet
            return -1;
          }(),
          onTap: (index) {
            const mapping = [0, 1, 2, 8, 9];
            setState(() => _selectedIndex = mapping[index]);
          },
          items: const [
            CustomMobileBottomBarItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: 'Dashboard',
            ),
            CustomMobileBottomBarItem(
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today,
              label: 'Timetable',
            ),
            CustomMobileBottomBarItem(
              icon: Icons.medical_services_outlined,
              activeIcon: Icons.medical_services,
              label: 'Assessment',
            ),
            CustomMobileBottomBarItem(
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment,
              label: 'IEP',
            ),
            CustomMobileBottomBarItem(
              icon: Icons.credit_card_outlined,
              activeIcon: Icons.credit_card,
              label: 'Data Sheet',
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

  Widget _buildMenuItem({
    required int index,
    required String title,
    required IconData icon,
    bool isDrawer = false,
  }) {
    final bool isSelected = _selectedIndex == index;
    const Color activeColor = Color(0xFFAB47BC);
    const Color inactiveColor = Color(0xFFA0A5BA);

    return InkWell(
      onTap: () {
        _onItemTapped(index);
        if (isDrawer) {
          Navigator.of(context).pop();
        }
      },
      hoverColor: const Color(0xFFF9FAFB),
      child: SizedBox(
        height: 52,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            if (isSelected)
              Positioned(
                left: 0,
                child: Container(
                  width: 6,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 28, right: 16),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableMenuItem({bool isDrawer = false}) {
    final bool isParentSelected = _isVbChildSelected();
    const Color activeColor = Color(0xFFAB47BC);
    const Color inactiveColor = Color(0xFFA0A5BA);

    return Column(
      children: [
        InkWell(
          onTap: _toggleVbAssessment,
          hoverColor: const Color(0xFFF9FAFB),
          child: SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (isParentSelected)
                  Positioned(
                    left: 0,
                    child: Container(
                      width: 6,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 28, right: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.volunteer_activism_outlined,
                        color: isParentSelected ? activeColor : inactiveColor,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'VB Assessment',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: isParentSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isParentSelected ? activeColor : inactiveColor,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isVbAssessmentExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: isParentSelected ? activeColor : inactiveColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _isVbAssessmentExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Column(
            children: [
              _buildSubMenuItem(index: 2, title: 'Milestone Assessment', isDrawer: isDrawer),
              _buildSubMenuItem(index: 3, title: 'Barriers Assessment', isDrawer: isDrawer),
              _buildSubMenuItem(index: 4, title: 'Transition Assessment', isDrawer: isDrawer),
              _buildSubMenuItem(index: 5, title: 'EES Assessment', isDrawer: isDrawer),
              _buildSubMenuItem(index: 6, title: 'Preference Assessment', isDrawer: isDrawer),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubMenuItem({
    required int index,
    required String title,
    bool isDrawer = false,
  }) {
    final bool isSelected = _selectedIndex == index;
    const Color activeColor = Color(0xFFAB47BC);
    const Color inactiveColor = Color(0xFFA0A5BA);

    return InkWell(
      onTap: () {
        _onItemTapped(index);
        if (isDrawer) {
          Navigator.of(context).pop();
        }
      },
      hoverColor: const Color(0xFFF9FAFB),
      child: Container(
        height: 44,
        padding: const EdgeInsets.only(left: 68, right: 16),
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? activeColor : inactiveColor,
          ),
        ),
      ),
    );
  }
}
