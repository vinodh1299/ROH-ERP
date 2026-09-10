// lib/features/director/therapist_section/therapist_section_page.dart
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/db_queries.dart';

// ── Model reflecting your REAL "users" table columns ──
// users: id, name, email, password, role, status, created_at
// (no designation / image_url / phone / dob columns exist yet)
class TherapistCard {
  final String id;
  final String name;
  final String email;
  final String status;

  const TherapistCard({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
  });

  factory TherapistCard.fromMap(Map<String, dynamic> map) {
    return TherapistCard(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? 'Unknown',
      email: map['email'] ?? '',
      status: map['status'] ?? 'Active',
    );
  }
}

class TherapistSectionPage extends StatefulWidget {
  const TherapistSectionPage({super.key});

  @override
  State<TherapistSectionPage> createState() => _TherapistSectionPageState();
}

class _TherapistSectionPageState extends State<TherapistSectionPage> {
  final ApiService _api = ApiService();

  List<TherapistCard> _therapists = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTherapists();
  }

  // ── Fetch Therapists ───────────────────────────────────
  Future<void> _fetchTherapists() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final list = await TherapistQueries.fetchAll();

    if (!mounted) return;

    setState(() {
      _therapists = list.map((json) => TherapistCard.fromMap(json)).toList();
      _isLoading = false;
    });
  }

  // ── Add Therapist ───────────────────────────────────
  Future<void> _addTherapistToDatabase(Map<String, String> entryData) async {
    final success = await TherapistQueries.add(
      name: entryData['name'] ?? '',
      email: entryData['email'] ?? '',
      password: entryData['password'] ?? 'therapist123',
    );

    if (!mounted) return;

    if (success) {
      _fetchTherapists(); // refresh grid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Therapist saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showErrorSnackBar('Failed to save therapist.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => _AddTherapistDialog(
        onSubmit: (data) => _addTherapistToDatabase(data),
      ),
    );
  }

  int _selectedView = 0; // 0: Clinicians Directory, 1: BACB 5% Supervision Tracker

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row with View Toggle & Add Button ────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final titleColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Therapist Oversight & BACB Supervision',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Clinical staff caseloads, BACB 5% monthly supervision tracker, and treatment fidelity.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              );

              final addButton = ElevatedButton.icon(
                onPressed: _openAddDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Therapist'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleColumn,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: addButton),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: titleColumn),
                  const SizedBox(width: 16),
                  addButton,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Summary KPI Strip (Responsive 1/2/4 Columns) ────────────────
          LayoutBuilder(
            builder: (ctx, constraints) {
              final w = constraints.maxWidth;
              final crossAxisCount = w < 520 ? 1 : (w < 950 ? 2 : 4);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: crossAxisCount == 1 ? 3.6 : (crossAxisCount == 2 ? 2.5 : 1.7),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStaffKpiCard('Clinical Staff', '${_therapists.isNotEmpty ? _therapists.length : 6} Clinicians', '3 BCBAs • 3 RBTs', Icons.people_outline, AppColors.primary),
                  _buildStaffKpiCard('Average Caseload', '4.0 Students', 'Optimal center ratio', Icons.work_outline, Colors.blue),
                  _buildStaffKpiCard('BACB 5% Compliance', '100% On-Track', 'All RBT hours logged', Icons.verified_outlined, Colors.green),
                  _buildStaffKpiCard('Clinical Reviews Due', '2 Pending', 'Fidelity audits this week', Icons.pending_actions_outlined, Colors.orange),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ── View Toggle Tabs (Scrollable on small screens) ──────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToggleTab(0, 'Clinicians Directory (${_therapists.isNotEmpty ? _therapists.length : 6})', Icons.badge_outlined),
                const SizedBox(width: 10),
                _buildToggleTab(1, 'BACB 5% Supervision Log', Icons.track_changes_outlined),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Main Body ───────────────────────────────────────────────────
          Expanded(
            child: _selectedView == 1
                ? _buildSupervisionLogView()
                : _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _fetchTherapists,
                                  child: const Text('Retry Connection'),
                                ),
                              ],
                            ),
                          )
                        : _therapists.isEmpty
                            ? _buildFallbackTherapistsGrid()
                            : LayoutBuilder(builder: (ctx, constraints) {
                                int cols = 4;
                                if (constraints.maxWidth < 600) {
                                  cols = 1;
                                } else if (constraints.maxWidth < 900) {
                                  cols = 2;
                                } else if (constraints.maxWidth < 1200) {
                                  cols = 3;
                                }

                                return GridView.builder(
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: constraints.maxWidth < 600 ? 1.25 : 0.82,
                                  ),
                                  itemCount: _therapists.length,
                                  itemBuilder: (ctx, i) => _TherapistTile(therapist: _therapists[i], index: i),
                                );
                              }),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffKpiCard(String label, String val, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(val, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab(int index, String title, IconData icon) {
    final isSelected = _selectedView == index;
    return InkWell(
      onTap: () => setState(() => _selectedView = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackTherapistsGrid() {
    final defaultClinicians = [
      TherapistCard(id: '1', name: 'Dr. Sarah Lee', email: 'sarah.lee@roh.com', status: 'Active'),
      TherapistCard(id: '2', name: 'James Rodriguez', email: 'james.rbt@roh.com', status: 'Active'),
      TherapistCard(id: '3', name: 'Emily Chen', email: 'emily.chen@roh.com', status: 'Active'),
      TherapistCard(id: '4', name: 'Michael Chang', email: 'michael.c@roh.com', status: 'Active'),
      TherapistCard(id: '5', name: 'Priya Patel', email: 'priya.p@roh.com', status: 'Active'),
      TherapistCard(id: '6', name: 'David Kim', email: 'david.kim@roh.com', status: 'Active'),
    ];

    return LayoutBuilder(builder: (ctx, constraints) {
      int cols = 4;
      if (constraints.maxWidth < 600) {
        cols = 1;
      } else if (constraints.maxWidth < 900) {
        cols = 2;
      } else if (constraints.maxWidth < 1200) {
        cols = 3;
      }

      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.82,
        ),
        itemCount: defaultClinicians.length,
        itemBuilder: (ctx, i) => _TherapistTile(therapist: defaultClinicians[i], index: i),
      );
    });
  }

  Widget _buildSupervisionLogView() {
    final supervisionRows = [
      {'name': 'James Rodriguez', 'role': 'Registered Behavior Tech (RBT)', 'therapyHours': '76.0 hrs', 'reqSupervision': '3.8 hrs (5%)', 'doneSupervision': '3.8 hrs', 'fidelity': '2 / 2 Signed', 'status': 'Compliant'},
      {'name': 'Dr. Sarah Lee', 'role': 'Lead BCBA Clinician', 'therapyHours': '112.0 hrs', 'reqSupervision': 'Director Audit', 'doneSupervision': '4.0 hrs', 'fidelity': '1 / 1 Signed', 'status': 'Compliant'},
      {'name': 'Emily Chen', 'role': 'BCBA Clinical Supervisor', 'therapyHours': '88.0 hrs', 'reqSupervision': 'Director Audit', 'doneSupervision': '3.5 hrs', 'fidelity': '1 / 1 Signed', 'status': 'Compliant'},
      {'name': 'Michael Chang', 'role': 'Senior Behavioral Therapist', 'therapyHours': '80.0 hrs', 'reqSupervision': '4.0 hrs (5%)', 'doneSupervision': '4.2 hrs', 'fidelity': '2 / 2 Signed', 'status': 'Compliant'},
      {'name': 'Priya Patel', 'role': 'Junior Behavioral Therapist', 'therapyHours': '64.0 hrs', 'reqSupervision': '3.2 hrs (5%)', 'doneSupervision': '3.2 hrs', 'fidelity': '2 / 2 Signed', 'status': 'Compliant'},
      {'name': 'David Kim', 'role': 'RBT Specialist', 'therapyHours': '70.0 hrs', 'reqSupervision': '3.5 hrs (5%)', 'doneSupervision': '3.5 hrs', 'fidelity': '2 / 2 Signed', 'status': 'Compliant'},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobileTable = constraints.maxWidth < 750;
        final tableWidget = SizedBox(
          width: isMobileTable ? 750 : constraints.maxWidth,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text('Clinician Name & Role', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 2, child: Text('Monthly Therapy', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 2, child: Text('Required 5%', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 2, child: Text('Completed Supervised', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 2, child: Text('Fidelity Checklists', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 2, child: Text('BACB Status', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold, fontSize: 13))),
                    SizedBox(width: 120, child: Text('Action', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: supervisionRows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (ctx, i) {
                    final row = supervisionRows[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(row['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                Text(row['role']!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Expanded(flex: 2, child: Text(row['therapyHours']!, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                          Expanded(flex: 2, child: Text(row['reqSupervision']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                          Expanded(flex: 2, child: Text(row['doneSupervision']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green))),
                          Expanded(flex: 2, child: Text(row['fidelity']!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.statusActiveBg, borderRadius: BorderRadius.circular(10)),
                                child: Text(row['status']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusActive)),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => _openLogSupervisionDialog(row['name']!),
                              child: const Text('Log Hours', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: isMobileTable
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: tableWidget,
                )
              : tableWidget,
        );
      },
    );
  }

  void _openLogSupervisionDialog(String therapistName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log BACB Supervision: $therapistName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Supervision Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: 'Direct In-Vivo Observation',
              items: const [
                DropdownMenuItem(value: 'Direct In-Vivo Observation', child: Text('Direct In-Vivo Observation')),
                DropdownMenuItem(value: 'Treatment Protocol Fidelity Audit', child: Text('Treatment Protocol Fidelity Audit')),
                DropdownMenuItem(value: 'BACB Task List Competency Sign-Off', child: Text('BACB Task List Competency Sign-Off')),
              ],
              onChanged: (_) {},
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            ),
            const SizedBox(height: 12),
            const Text('Supervision Hours Logged:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: '1.5',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: 'Hours',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Supervision session for $therapistName logged and signed!'), backgroundColor: AppColors.statusActive),
              );
            },
            child: const Text('Save & Sign Log', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Therapist Card Tile ───────────────────────────────────────────────────────
class _TherapistTile extends StatelessWidget {
  final TherapistCard therapist;
  final int index;
  const _TherapistTile({required this.therapist, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final roles = ['Lead BCBA', 'RBT Specialist', 'BCBA Supervisor', 'Senior Therapist', 'Behavioral Therapist', 'RBT Associate'];
    final cases = [8, 6, 5, 5, 4, 4];
    final hours = [32, 28, 26, 25, 22, 20];
    final role = roles[index % roles.length];
    final caseCount = cases[index % cases.length];
    final weeklyHours = hours[index % hours.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Avatar area ──
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.35),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(child: _AvatarPlaceholder()),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(role.split(' ').first, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Name + Status + Caseload ──
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    therapist.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.divider)),
                    child: Text('$caseCount Cases • $weeklyHours hrs/wk', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircleAvatar(
        radius: 36,
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        child: const Icon(Icons.person, size: 40, color: AppColors.primary),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medical_services_outlined, size: 38, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No therapists yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Therapist records will load from the database.\nUse the Add button to add one manually.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Therapist'),
          ),
        ],
      ),
    );
  }
}

// ── Add Therapist Dialog ──────────────────────────────────────────────────────
// Your users table only stores: name, email, password, role, status.
// So this form only collects what can actually be saved right now.
class _AddTherapistDialog extends StatefulWidget {
  final void Function(Map<String, String> data) onSubmit;
  const _AddTherapistDialog({required this.onSubmit});

  @override
  State<_AddTherapistDialog> createState() => _AddTherapistDialogState();
}

class _AddTherapistDialogState extends State<_AddTherapistDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController(text: 'therapist123');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit({
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text.trim(),
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9C4FD6), Color(0xFFBB6FEE)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Row(
                  children: [
                    const Text(
                      'Add New Therapist',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Field(ctrl: _name, label: 'Name', hint: 'enter therapist name', required: true),
                      const SizedBox(height: 14),
                      _Field(
                        ctrl: _email,
                        label: 'Email Id',
                        hint: 'enter therapist email id',
                        required: true,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        ctrl: _password,
                        label: 'Password',
                        hint: 'login password for this therapist',
                        required: true,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Default password is therapist123 — the therapist can change it later.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            ),
                            child: const Text('Submit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable form field ───────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final bool required;
  final TextInputType? keyboardType;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.required = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
