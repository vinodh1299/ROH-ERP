import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_constants.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import '../../core/layout/responsive.dart';
import '../../core/widgets/custom_mobile_bottom_bar.dart';
import '../../core/widgets/animated_top_bar_title.dart';
import '../../core/widgets/two_step_logout_dialog.dart';
import '../../core/widgets/notification_center_drawer.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/system_notifications.dart';
import '../../core/services/schedule_service.dart';
import '../../core/services/session_reminders.dart';
import '../auth/auth_service.dart';
import '../auth/widgets/forced_password_change_dialog.dart';
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
  final int initialTab;
  const TherapistShell({super.key, this.initialTab = 0});

  @override
  State<TherapistShell> createState() => _TherapistShellState();
}

class _TherapistShellState extends State<TherapistShell> {
  late int _selectedIndex;
  bool _isVbAssessmentExpanded = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    if (_selectedIndex >= 2 && _selectedIndex <= 7) {
      _isVbAssessmentExpanded = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (!auth.isLoggedIn || auth.currentUser?.role != 'therapist') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppConstants.routeLogin,
          (route) => false,
        );
        return;
      }
      ForcedPasswordChangeDialog.showIfNeeded(context);
      NotificationService().fetchNotifications();
      SystemNotifications.requestPermission();
      ScheduleService().addListener(_syncSessionReminders);
      _syncSessionReminders();
    });
  }

  @override
  void dispose() {
    ScheduleService().removeListener(_syncSessionReminders);
    super.dispose();
  }

  /// Keeps the 5-minute-before alerts in step with this therapist's sessions.
  void _syncSessionReminders() {
    final me = context.read<AuthService>().currentUser?.id.toString();
    if (me == null) return;
    SessionReminders.sync(ScheduleService()
        .allSessions
        .where((s) => s.therapistId == me)
        .toList());
  }

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
    final screen = Breakpoints.of(context);
    final isMobile = screen == ScreenSize.compact;
    // Tablet (600–1023): collapse the sidebar to a compact icon rail.
    final isRail = screen == ScreenSize.medium;

    final sidebarWidget = isRail
        ? _buildRail()
        : Container(
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
                        title: 'Daily Data Analysis',
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
        color: AppColors.surface,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 28),
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
              width: isMobile ? 36 : 40,
              height: isMobile ? 36 : 40,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(
                      Icons.notifications_none,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                  ),
                  ListenableBuilder(
                    listenable: NotificationService(),
                    builder: (context, _) {
                      final count = NotificationService().unreadCount;
                      if (count <= 0) return const SizedBox.shrink();
                      return Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Color(0xFFEF4444), shape: BoxShape.circle),
                          constraints:
                              const BoxConstraints(minWidth: 14, minHeight: 14),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
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
            tooltip: 'Profile',
            offset: const Offset(0, 48),
            onSelected: (value) async {
              if (value == 'logout') {
                final shouldLogout = await TwoStepLogoutDialog.show(context);
                if (shouldLogout == true && context.mounted) {
                  await context.read<AuthService>().logout();
                  if (context.mounted) {
                    Navigator.of(context)
                        .pushReplacementNamed(AppConstants.routeLogin);
                  }
                }
              }
            },
            itemBuilder: (context) => [
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
            if (_isVbChildSelected() || _selectedIndex == 7)
              return 2; // VB Assessment / Milestones
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

  /// Compact icon rail used at tablet widths (600–1023). Every destination
  /// stays reachable: the VB Assessment group opens its five sub-pages as a
  /// popup menu.
  Widget _buildRail() {
    return Container(
      width: 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE6EFF5), width: 1),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _onItemTapped(0),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 72,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: AppImages.rohLogo(height: 30),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildRailItem(index: 0, title: 'Dashboard', icon: Icons.home),
                _buildRailItem(
                    index: 1,
                    title: 'Time Table',
                    icon: Icons.calendar_today_outlined),
                _buildRailVbAssessment(),
                _buildRailItem(
                    index: 7, title: 'VB Milestone', icon: Icons.person),
                _buildRailItem(index: 8, title: 'IEP', icon: Icons.bar_chart),
                _buildRailItem(
                    index: 9,
                    title: 'Daily Data Analysis',
                    icon: Icons.credit_card),
                _buildRailItem(
                    index: 10, title: 'Profile', icon: Icons.settings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _railTile({
    required bool isSelected,
    required IconData icon,
    bool showMenuHint = false,
  }) {
    const Color activeColor = AppColors.primary;
    const Color inactiveColor = AppColors.textSecondary;
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isSelected)
            Positioned(
              left: 0,
              child: Container(
                width: 5,
                height: 40,
                decoration: const BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
              ),
            ),
          Container(
            width: 44,
            height: 40,
            decoration: BoxDecoration(
              color:
                  isSelected ? AppColors.sidebarSelectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
          ),
          if (showMenuHint)
            Positioned(
              right: 6,
              child: Icon(
                Icons.chevron_right,
                size: 14,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRailItem({
    required int index,
    required String title,
    required IconData icon,
  }) {
    return Tooltip(
      message: title,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: () => _onItemTapped(index),
        hoverColor: const Color(0xFFF9FAFB),
        child: _railTile(isSelected: _selectedIndex == index, icon: icon),
      ),
    );
  }

  Widget _buildRailVbAssessment() {
    const subItems = <(int, String)>[
      (2, 'Milestone Assessment'),
      (3, 'Barriers Assessment'),
      (4, 'Transition Assessment'),
      (5, 'EES Assessment'),
      (6, 'Preference Assessment'),
    ];
    return PopupMenuButton<int>(
      tooltip: 'VB Assessment',
      offset: const Offset(76, 0),
      onSelected: _onItemTapped,
      itemBuilder: (context) => [
        const PopupMenuItem<int>(
          enabled: false,
          child: Text(
            'VB Assessment',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        for (final (index, title) in subItems)
          PopupMenuItem<int>(
            value: index,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: _selectedIndex == index
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: _selectedIndex == index
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ),
      ],
      child: _railTile(
        isSelected: _isVbChildSelected(),
        icon: Icons.volunteer_activism_outlined,
        showMenuHint: true,
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
    const Color activeColor = AppColors.primary;
    const Color inactiveColor = AppColors.textSecondary;

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
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
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
    const Color activeColor = AppColors.primary;
    const Color inactiveColor = AppColors.textSecondary;

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
                            fontWeight: isParentSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color:
                                isParentSelected ? activeColor : inactiveColor,
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
          crossFadeState: _isVbAssessmentExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Column(
            children: [
              _buildSubMenuItem(
                  index: 2, title: 'Milestone Assessment', isDrawer: isDrawer),
              _buildSubMenuItem(
                  index: 3, title: 'Barriers Assessment', isDrawer: isDrawer),
              _buildSubMenuItem(
                  index: 4, title: 'Transition Assessment', isDrawer: isDrawer),
              _buildSubMenuItem(
                  index: 5, title: 'EES Assessment', isDrawer: isDrawer),
              _buildSubMenuItem(
                  index: 6, title: 'Preference Assessment', isDrawer: isDrawer),
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
    const Color activeColor = AppColors.primary;
    const Color inactiveColor = AppColors.textSecondary;

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
