// lib/features/director/dashboard/director_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/auth_service.dart';

class DirectorDashboardPage extends StatelessWidget {
  const DirectorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final now = DateTime.now();
    const dayNames = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final dateStr =
        '${now.day.toString().padLeft(2,'0')}-${now.month.toString().padLeft(2,'0')}-${now.year} ${dayNames[now.weekday - 1]}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 600;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _WelcomeCard(name: user?.name ?? 'Admin', dateStr: dateStr)),
                      const SizedBox(width: 20),
                      const Expanded(flex: 6, child: _PendingIepCard()),
                    ],
                  )
                : Column(children: [
                    _WelcomeCard(name: user?.name ?? 'Admin', dateStr: dateStr),
                    const SizedBox(height: 16),
                    const _PendingIepCard(),
                  ]);
          }),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: _StatCard(label: 'Students', icon: Icons.people_outline, iconColor: AppColors.primary, iconBg: Color(0xFFF3E8FF))),
              SizedBox(width: 16),
              Expanded(child: _StatCard(label: 'Staffs', icon: Icons.badge_outlined, iconColor: AppColors.accentTeal, iconBg: Color(0xFFE0F7FA))),
            ],
          ),
          const SizedBox(height: 28),
          const _RecentActivitiesSection(),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;
  final String dateStr;
  const _WelcomeCard({required this.name, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: AppColors.welcomeGradient, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hi, $name !', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Welcome back to the work station', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(dateStr, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _PendingIepCard extends StatelessWidget {
  const _PendingIepCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pending IEP Reports', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          const _EmptyState(icon: Icons.assignment_outlined, message: 'No pending IEP reports.\nData will load from database.'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  const _StatCard({required this.label, required this.icon, required this.iconColor, required this.iconBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              const Text('—', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentActivitiesSection extends StatefulWidget {
  const _RecentActivitiesSection();
  @override
  State<_RecentActivitiesSection> createState() => _RecentActivitiesSectionState();
}

class _RecentActivitiesSectionState extends State<_RecentActivitiesSection> with SingleTickerProviderStateMixin {
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
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text('Recent Activities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            tabs: const [Tab(text: 'Recent Students'), Tab(text: 'Recent IEP Requested')],
          ),
          const Divider(height: 1, color: AppColors.divider),
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabController,
              children: [_StudentsTable(), _IepTable()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentsTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFFAF5FF),
          child: Row(children: const [
            Expanded(flex: 3, child: _TH('Name')),
            Expanded(flex: 3, child: _TH('Email Id')),
            Expanded(flex: 2, child: _TH('Phone')),
            Expanded(flex: 2, child: _TH('Age')),
            Expanded(flex: 3, child: _TH('Created Date')),
            Expanded(flex: 2, child: _TH('Status')),
            Expanded(flex: 2, child: _TH('')),
          ]),
        ),
        const Divider(height: 1, color: AppColors.divider),
        const Expanded(child: Center(child: _EmptyState(icon: Icons.people_outline, message: 'Student records will appear here\nonce connected to the database.'))),
      ],
    );
  }
}

class _IepTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: _EmptyState(icon: Icons.assignment_outlined, message: 'IEP requests will appear here\nonce connected to the database.'));
  }
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.tableHeaderText));
  }
}

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
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textHint, height: 1.5)),
        ],
      ),
    );
  }
}
