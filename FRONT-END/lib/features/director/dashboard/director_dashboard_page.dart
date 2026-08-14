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
              Expanded(child: _StatCard(label: 'Students', value: '6', icon: Icons.people_outline, iconColor: AppColors.primary, iconBg: Color(0xFFF3E8FF))),
              SizedBox(width: 16),
              Expanded(child: _StatCard(label: 'Staffs', value: '6', icon: Icons.badge_outlined, iconColor: AppColors.accentTeal, iconBg: Color(0xFFE0F7FA))),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pending IEP Reports', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.statusPendingBg, borderRadius: BorderRadius.circular(12)),
                child: const Text('2 Pending', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.statusPending)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PendingIepTile(title: 'Q3 Behavioral Plan', student: 'Aarav Patel', date: '2026-07-10'),
          const SizedBox(height: 8),
          _PendingIepTile(title: 'Occupational Therapy', student: 'Rahul Sharma', date: '2026-07-15'),
        ],
      ),
    );
  }
}

class _PendingIepTile extends StatelessWidget {
  final String title;
  final String student;
  final String date;
  const _PendingIepTile({required this.title, required this.student, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.scaffold, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.assignment_outlined, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('Student: $student • $date', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  const _StatCard({required this.label, required this.value, required this.icon, required this.iconColor, required this.iconBg});

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
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
    final sampleStudents = [
      {'name': 'Aarav Patel', 'email': 'parent.aarav@roh.com', 'phone': '+1 (555) 019-2831', 'age': '8', 'date': '14-05-2026', 'status': 'Active'},
      {'name': 'Emma Watson', 'email': 'parent.emma@roh.com', 'phone': '+1 (555) 014-9284', 'age': '7', 'date': '20-05-2026', 'status': 'Active'},
      {'name': 'Rahul Sharma', 'email': 'parent.rahul@roh.com', 'phone': '+1 (555) 018-4720', 'age': '9', 'date': '03-06-2026', 'status': 'Active'},
      {'name': 'Sophia Garcia', 'email': 'parent.sophia@roh.com', 'phone': '+1 (555) 016-3912', 'age': '6', 'date': '17-06-2026', 'status': 'Active'},
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFFAF5FF),
          child: Row(children: const [
            Expanded(flex: 3, child: _TH('Name')),
            Expanded(flex: 3, child: _TH('Email Id')),
            Expanded(flex: 2, child: _TH('Phone')),
            Expanded(flex: 1, child: _TH('Age')),
            Expanded(flex: 2, child: _TH('Created Date')),
            Expanded(flex: 2, child: _TH('Status')),
          ]),
        ),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: ListView.separated(
            itemCount: sampleStudents.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (ctx, i) {
              final s = sampleStudents[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(s['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                    Expanded(flex: 3, child: Text(s['email']!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                    Expanded(flex: 2, child: Text(s['phone']!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                    Expanded(flex: 1, child: Text(s['age']!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                    Expanded(flex: 2, child: Text(s['date']!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.statusActiveBg, borderRadius: BorderRadius.circular(10)),
                        child: Text(s['status']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.statusActive)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _IepTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sampleIeps = [
      {'title': 'Q3 Behavioral Plan', 'student': 'Aarav Patel', 'date': '10-07-2026', 'status': 'Pending Approval'},
      {'title': 'Speech Therapy Assessment', 'student': 'Emma Watson', 'date': '12-07-2026', 'status': 'Active'},
      {'title': 'Occupational Therapy', 'student': 'Rahul Sharma', 'date': '15-07-2026', 'status': 'Pending Approval'},
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFFAF5FF),
          child: Row(children: const [
            Expanded(flex: 3, child: _TH('Title')),
            Expanded(flex: 3, child: _TH('Student Name')),
            Expanded(flex: 2, child: _TH('Date')),
            Expanded(flex: 2, child: _TH('Status')),
          ]),
        ),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: ListView.separated(
            itemCount: sampleIeps.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (ctx, i) {
              final iep = sampleIeps[i];
              final isPending = iep['status'] == 'Pending Approval';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(iep['title']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                    Expanded(flex: 3, child: Text(iep['student']!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                    Expanded(flex: 2, child: Text(iep['date']!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: isPending ? AppColors.statusPendingBg : AppColors.statusActiveBg, borderRadius: BorderRadius.circular(10)),
                        child: Text(iep['status']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isPending ? AppColors.statusPending : AppColors.statusActive)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
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
