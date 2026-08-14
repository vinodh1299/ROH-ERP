// lib/features/therapist/dashboard/therapist_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/auth_service.dart';

class TherapistDashboardPage extends StatelessWidget {
  const TherapistDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final now = DateTime.now();
    const dayNames = [
      'Monday','Tuesday','Wednesday','Thursday',
      'Friday','Saturday','Sunday'
    ];
    final dateStr =
        '${now.day.toString().padLeft(2,'0')}-'
        '${now.month.toString().padLeft(2,'0')}-'
        '${now.year} ${dayNames[now.weekday - 1]}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Welcome + Today's Sessions ──────────────────────────
          LayoutBuilder(builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 600;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _WelcomeCard(
                          name: user?.name ?? 'Therapist',
                          dateStr: dateStr,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(flex: 6, child: _TodaysSessionsCard()),
                    ],
                  )
                : Column(children: [
                    _WelcomeCard(
                      name: user?.name ?? 'Therapist',
                      dateStr: dateStr,
                    ),
                    const SizedBox(height: 16),
                    const _TodaysSessionsCard(),
                  ]);
          }),
          const SizedBox(height: 20),

          // ── Row 2: Total Students + Today's Sessions stats ─────────────
          Row(
            children: const [
              Expanded(
                child: _StatCard(
                  label: 'Total Students',
                  icon: Icons.people_outline,
                  iconColor: Color(0xFFE91E8C),
                  iconBg: Color(0xFFFCE4EC),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'Todays Sessions',
                  icon: Icons.calendar_today_outlined,
                  iconColor: AppColors.accentTeal,
                  iconBg: Color(0xFFE0F7FA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Recent Activities ───────────────────────────────────────────
          const _RecentActivitiesSection(),
        ],
      ),
    );
  }
}

// ── Welcome Card ──────────────────────────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final String name;
  final String dateStr;
  const _WelcomeCard({required this.name, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    // Extract first name for the greeting
    final firstName = name.split(' ').first;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, $firstName !',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Welcome back to the work station',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dateStr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Today's Sessions Card ─────────────────────────────────────────────────────
class _TodaysSessionsCard extends StatelessWidget {
  const _TodaysSessionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Todays Sessions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Empty state – populate from DB
          const _EmptyState(
            icon: Icons.event_note_outlined,
            message: "Today's sessions will appear here\nonce connected to the database.",
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  const _StatCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '—',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Recent Activities Section ─────────────────────────────────────────────────
class _RecentActivitiesSection extends StatefulWidget {
  const _RecentActivitiesSection();

  @override
  State<_RecentActivitiesSection> createState() =>
      _RecentActivitiesSectionState();
}

class _RecentActivitiesSectionState extends State<_RecentActivitiesSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            tabs: const [
              Tab(text: 'Recent IEP Requested'),
              Tab(text: 'Returned IEP'),
            ],
          ),
          const Divider(height: 1, color: AppColors.divider),
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tabController,
              children: [
                _IepTable(),
                _IepTable(isReturned: true),
              ],
            ),
          ),
          // ── Pagination ─────────────────────────────────────────────────
          const _Pagination(),
        ],
      ),
    );
  }
}

// ── IEP Table ─────────────────────────────────────────────────────────────────
class _IepTable extends StatelessWidget {
  final bool isReturned;
  const _IepTable({this.isReturned = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 500;
      return Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFFFAF5FF),
            child: Row(
              children: [
                const Expanded(flex: 3, child: _TH('Name')),
                if (!isNarrow) const Expanded(flex: 3, child: _TH('Email Id')),
                if (!isNarrow) const Expanded(flex: 2, child: _TH('Phone')),
                const Expanded(flex: 1, child: _TH('Age')),
                if (!isNarrow) const Expanded(flex: 3, child: _TH('Created Date')),
                const Expanded(flex: 2, child: _TH('Status')),
                const Expanded(flex: 2, child: _TH('')),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          // Empty state
          const Expanded(
            child: Center(
              child: _EmptyState(
                icon: Icons.assignment_outlined,
                message: 'IEP records will appear here\nonce connected to the database.',
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ── Pagination ────────────────────────────────────────────────────────────────
class _Pagination extends StatefulWidget {
  const _Pagination();

  @override
  State<_Pagination> createState() => _PaginationState();
}

class _PaginationState extends State<_Pagination> {
  int _current = 1;
  final int _total = 4;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Previous
          _PagButton(
            label: 'Previous',
            isText: true,
            enabled: _current > 1,
            onTap: () => setState(() => _current--),
          ),
          const SizedBox(width: 4),
          // Page numbers
          ...List.generate(_total, (i) {
            final page = i + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _PagButton(
                label: '$page',
                isActive: _current == page,
                onTap: () => setState(() => _current = page),
              ),
            );
          }),
          const SizedBox(width: 4),
          // Next
          _PagButton(
            label: 'Next',
            isText: true,
            enabled: _current < _total,
            onTap: () => setState(() => _current++),
          ),
        ],
      ),
    );
  }
}

class _PagButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isText;
  final bool enabled;
  final VoidCallback? onTap;

  const _PagButton({
    required this.label,
    this.isActive = false,
    this.isText = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isText) {
      return TextButton(
        onPressed: enabled ? onTap : null,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 32),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive ? null : Border.all(color: AppColors.divider),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Table Header Cell ─────────────────────────────────────────────────────────
class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.tableHeaderText,
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: AppColors.textHint),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
