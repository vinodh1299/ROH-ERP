// lib/features/admin/students/admin_students_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminStudentsPage extends StatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  State<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends State<AdminStudentsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          // Sub-Tab Switcher Bar matching ADMIN STUDENTS *.png
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.info_outline), text: 'Student Info'),
                Tab(icon: Icon(Icons.trending_up), text: 'Progress Overview'),
                Tab(icon: Icon(Icons.medical_information_outlined), text: 'Medication History'),
                Tab(icon: Icon(Icons.emergency_outlined), text: 'Emergency Contacts'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(context),
                _buildProgressTab(context),
                _buildMedicationTab(context),
                _buildEmergencyTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Student Info (ADMIN STUDENTS INFO.png) ──────────────────────────
  Widget _buildInfoTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 30, backgroundColor: Colors.purple, child: Text('A', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Aarav Patel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('DOB: 2018-04-12 | Age: 8 | Gender: Male | ID: STU-1002', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            const Text('Guardian Details:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Parent Name: Rajesh Patel | Phone: +1 (555) 345-6789 | Email: rajesh.patel@gmail.com', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            const Text('Therapy Enrollment:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Primary Therapist: Sarah Adams (BCBA) | Center Branch: Main Campus | Hours/Wk: 25 hrs', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Progress Overview (ADMIN STUDENTS PROGRESS.png) ────────────────
  Widget _buildProgressTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Student Progress Summary & Domain Achievements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildProgressBar('VB-MAPP Milestone Level 1', 1.0, Colors.green),
            const SizedBox(height: 12),
            _buildProgressBar('VB-MAPP Milestone Level 2', 0.85, Colors.orange),
            const SizedBox(height: 12),
            _buildProgressBar('VB-MAPP Milestone Level 3', 0.70, Colors.blue),
            const SizedBox(height: 12),
            _buildProgressBar('Behavior Reduction Target Baseline', 0.90, Colors.purple),
          ],
        ),
      ),
    );
  }

  // ── Tab 3: Medication History (ADMIN STUDENTS MEDICATION HISTORY.png) ────
  Widget _buildMedicationTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Medication & Medical Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add, size: 16), label: const Text('Add Medication Entry')),
              ],
            ),
            const SizedBox(height: 16),
            DataTable(
              columns: const [
                DataColumn(label: Text('Medication')),
                DataColumn(label: Text('Dosage')),
                DataColumn(label: Text('Schedule')),
                DataColumn(label: Text('Prescribing Doctor')),
              ],
              rows: const [
                DataRow(cells: [
                  DataCell(Text('Multivitamin Chewables', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('1 Tablet')),
                  DataCell(Text('Daily 9:00 AM')),
                  DataCell(Text('Dr. H. Vance')),
                ]),
                DataRow(cells: [
                  DataCell(Text('Melatonin (Optional)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('2.5 mg')),
                  DataCell(Text('As Needed (Evening)')),
                  DataCell(Text('Dr. H. Vance')),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 4: Emergency Contacts (ADMIN STUDENTS EMERGENCY CONTACT.png & Add.png)
  Widget _buildEmergencyTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Emergency Contacts & Medical Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddEmergencyContactDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Emergency Contact'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DataTable(
              columns: const [
                DataColumn(label: Text('Contact Name')),
                DataColumn(label: Text('Relationship')),
                DataColumn(label: Text('Phone Number')),
                DataColumn(label: Text('Priority')),
              ],
              rows: const [
                DataRow(cells: [
                  DataCell(Text('Rajesh Patel', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('Father')),
                  DataCell(Text('+1 (555) 345-6789')),
                  DataCell(Text('Primary Emergency')),
                ]),
                DataRow(cells: [
                  DataCell(Text('Priya Patel', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('Mother')),
                  DataCell(Text('+1 (555) 345-6790')),
                  DataCell(Text('Secondary Emergency')),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String title, double factor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${(factor * 100).toInt()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: factor, backgroundColor: Colors.grey.shade200, color: color, minHeight: 8),
      ],
    );
  }

  void _showAddEmergencyContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(decoration: InputDecoration(labelText: 'Full Name')),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Relationship (e.g. Mother, Uncle)')),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency Contact Added!'), backgroundColor: Colors.green));
            },
            child: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }
}
