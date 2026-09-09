// lib/features/admin/iep_reports/admin_iep_reports_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminIepReportsPage extends StatefulWidget {
  const AdminIepReportsPage({super.key});

  @override
  State<AdminIepReportsPage> createState() => _AdminIepReportsPageState();
}

class _AdminIepReportsPageState extends State<AdminIepReportsPage> {
  int _viewMode = 0; // 0 = Directory List (ADMIN IEP REPORTS.png), 1 = Report Detail View (ADMIN IEP REPORTS VIEW.png)
  Map<String, dynamic>? _selectedReport;

  final List<Map<String, dynamic>> _reports = [
    {
      'student': 'Aarav Patel (Age: 8)',
      'therapist': 'Sarah Adams (BCBA)',
      'quarter': 'Q3 2026',
      'domain': 'Language & Behavioral',
      'progress': '84%',
      'status': 'Approved',
      'date': '2026-09-01',
    },
    {
      'student': 'Emma Watson (Age: 7)',
      'therapist': 'Michael Chen (RBT)',
      'quarter': 'Q3 2026',
      'domain': 'Social & Fine Motor',
      'progress': '76%',
      'status': 'Pending Review',
      'date': '2026-09-04',
    },
    {
      'student': 'Rahul Sharma (Age: 9)',
      'therapist': 'Sarah Adams (BCBA)',
      'quarter': 'Q2 2026',
      'domain': 'VB-MAPP Level 3',
      'progress': '91%',
      'status': 'Approved',
      'date': '2026-06-30',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner with Frame Switcher
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_turned_in, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Center IEP Reports Management',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text('Admin Approval & Clinical Quality Governance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                // Switcher Buttons
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _viewMode = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _viewMode == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Reports Directory',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _viewMode == 0 ? const Color(0xFF1565C0) : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _viewMode = 1;
                          _selectedReport ??= _reports[0];
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _viewMode == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Report Detail View',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _viewMode == 1 ? const Color(0xFF1565C0) : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Content body based on frame switch
          _viewMode == 0 ? _buildDirectoryView(context) : _buildDetailView(context),
        ],
      ),
    );
  }

  // Frame 1: Directory List (ADMIN IEP REPORTS.png)
  Widget _buildDirectoryView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('All Submitted IEP Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DataTable(
            columns: const [
              DataColumn(label: Text('Student')),
              DataColumn(label: Text('Therapist')),
              DataColumn(label: Text('Quarter')),
              DataColumn(label: Text('Target Progress')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Action')),
            ],
            rows: _reports.map((r) {
              final isApproved = r['status'] == 'Approved';
              return DataRow(cells: [
                DataCell(Text(r['student'], style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(r['therapist'])),
                DataCell(Text(r['quarter'])),
                DataCell(Text(r['progress'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: isApproved ? Colors.green.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Text(r['status'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isApproved ? Colors.green : Colors.orange)),
                  ),
                ),
                DataCell(
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedReport = r;
                        _viewMode = 1;
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: const Text('View Detail'),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Frame 2: Detail View (ADMIN IEP REPORTS VIEW.png)
  Widget _buildDetailView(BuildContext context) {
    final r = _selectedReport ?? _reports[0];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${r['student']} — Comprehensive IEP Evaluation Report', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IEP Approved by Admin!'), backgroundColor: Colors.green));
                },
                icon: const Icon(Icons.check_circle, size: 16),
                label: const Text('Approve IEP'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoBadge('Therapist', r['therapist']),
              const SizedBox(width: 16),
              _buildInfoBadge('Evaluation Quarter', r['quarter']),
              const SizedBox(width: 16),
              _buildInfoBadge('Target Completion', r['progress']),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Clinical Observations & Goal Metrics:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'The student has demonstrated significant progress across Language, Social Interaction, and Motor Imitation goals. Behavior reduction strategies have met targeted benchmarks with low disruption recorded.',
            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String title, String val) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
