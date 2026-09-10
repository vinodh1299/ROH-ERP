// lib/features/director/iep_reports_section/iep_reports_section_page.dart
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';

enum IepStatus {
  pending('Pending Audit', AppColors.statusPending, AppColors.statusPendingBg),
  approved('Approved & Active', AppColors.statusActive, AppColors.statusActiveBg),
  returned('Revision Needed', AppColors.statusDeactivated, AppColors.statusDeactivatedBg);

  final String label;
  final Color color;
  final Color bgColor;
  const IepStatus(this.label, this.color, this.bgColor);
}

class IepReportItem {
  final String id;
  final String studentName;
  final int age;
  final String therapistName;
  final String cycle;
  final String targetDomains;
  final String submittedDate;
  IepStatus status;
  String? directorNotes;
  String? signDate;

  IepReportItem({
    required this.id,
    required this.studentName,
    required this.age,
    required this.therapistName,
    required this.cycle,
    required this.targetDomains,
    required this.submittedDate,
    required this.status,
    this.directorNotes,
    this.signDate,
  });
}

class IepReportsSectionPage extends StatefulWidget {
  const IepReportsSectionPage({super.key});

  @override
  State<IepReportsSectionPage> createState() => _IepReportsSectionPageState();
}

class _IepReportsSectionPageState extends State<IepReportsSectionPage> {
  int _selectedFilterIndex = 0; // 0: All, 1: Pending, 2: Approved, 3: Returned
  String _searchQuery = '';

  final List<IepReportItem> _reports = [
    IepReportItem(
      id: 'IEP-2026-001',
      studentName: 'Alex Thomas Sam',
      age: 15,
      therapistName: 'Dr. Sarah Lee (BCBA)',
      cycle: 'Annual 2026-2027',
      targetDomains: 'Manding, Tacting, Echoic (12 Targets)',
      submittedDate: '18-08-2026',
      status: IepStatus.pending,
    ),
    IepReportItem(
      id: 'IEP-2026-002',
      studentName: 'Matt Dickerson',
      age: 14,
      therapistName: 'James Rodriguez (RBT)',
      cycle: 'Q3 Behavioral Plan',
      targetDomains: 'Listener Responding, BIP Protocol (8 Targets)',
      submittedDate: '17-08-2026',
      status: IepStatus.pending,
    ),
    IepReportItem(
      id: 'IEP-2026-003',
      studentName: 'Wade Warren',
      age: 12,
      therapistName: 'Dr. Sarah Lee (BCBA)',
      cycle: 'Annual 2026-2027',
      targetDomains: 'Motor Imitation, Social Play (10 Targets)',
      submittedDate: '16-08-2026',
      status: IepStatus.pending,
    ),
    IepReportItem(
      id: 'IEP-2026-004',
      studentName: 'Esther Howard',
      age: 11,
      therapistName: 'Emily Chen (BCBA)',
      cycle: 'Semi-Annual 2026',
      targetDomains: 'Manding, Independent Living (15 Targets)',
      submittedDate: '10-08-2026',
      status: IepStatus.approved,
      signDate: '12-08-2026',
    ),
    IepReportItem(
      id: 'IEP-2026-005',
      studentName: 'Cameron Williamson',
      age: 13,
      therapistName: 'James Rodriguez (RBT)',
      cycle: 'Annual 2026-2027',
      targetDomains: 'Intraverbal, Tacting (14 Targets)',
      submittedDate: '08-08-2026',
      status: IepStatus.approved,
      signDate: '09-08-2026',
    ),
    IepReportItem(
      id: 'IEP-2026-006',
      studentName: 'Brooklyn Simmons',
      age: 16,
      therapistName: 'Emily Chen (BCBA)',
      cycle: 'Functional Communication Plan',
      targetDomains: 'AAC Manding, Vocalization (6 Targets)',
      submittedDate: '05-08-2026',
      status: IepStatus.returned,
      directorNotes: 'Baseline manding data insufficient. Please attach last 5 daily session probe logs.',
    ),
    IepReportItem(
      id: 'IEP-2026-007',
      studentName: 'Leslie Alexander',
      age: 10,
      therapistName: 'Dr. Sarah Lee (BCBA)',
      cycle: 'Annual 2026-2027',
      targetDomains: 'VB-MAPP Level 1 Complete (16 Targets)',
      submittedDate: '02-08-2026',
      status: IepStatus.approved,
      signDate: '04-08-2026',
    ),
    IepReportItem(
      id: 'IEP-2026-008',
      studentName: 'Guy Hawkins',
      age: 9,
      therapistName: 'Michael Chang (Therapist)',
      cycle: 'Sensory & Motor IEP',
      targetDomains: 'Fine Motor, Self-Regulation (8 Targets)',
      submittedDate: '01-08-2026',
      status: IepStatus.returned,
      directorNotes: 'Need occupational therapist co-signature before clinical director approval.',
    ),
  ];

  List<IepReportItem> get _filteredReports {
    return _reports.where((item) {
      if (_selectedFilterIndex == 1 && item.status != IepStatus.pending) return false;
      if (_selectedFilterIndex == 2 && item.status != IepStatus.approved) return false;
      if (_selectedFilterIndex == 3 && item.status != IepStatus.returned) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final match = item.studentName.toLowerCase().contains(query) ||
            item.therapistName.toLowerCase().contains(query) ||
            item.cycle.toLowerCase().contains(query);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  void _openAuditDialog(IepReportItem report) {
    final notesController = TextEditingController(text: report.directorNotes ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: screenWidth > 860 ? 820 : screenWidth * 0.94,
                constraints: const BoxConstraints(maxHeight: 700),
                padding: EdgeInsets.all(screenWidth < 600 ? 16 : 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clinical Director IEP Audit: ${report.studentName}',
                                style: TextStyle(fontSize: screenWidth < 600 ? 15 : 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                'Program Cycle: ${report.cycle} | Submitted by: ${report.therapistName}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: report.status.bgColor, borderRadius: BorderRadius.circular(12)),
                          child: Text(report.status.label, style: TextStyle(color: report.status.color, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textHint),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 32, color: AppColors.divider),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 3-Column Clinical Summary Cards (Responsive)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 600;
                                if (isNarrow) {
                                  return Column(
                                    children: [
                                      _auditSummaryCard('Student Age', '${report.age} Years', Icons.person_outline, Colors.blue),
                                      const SizedBox(height: 8),
                                      _auditSummaryCard('Mastery Criteria', '80% across 3 days', Icons.track_changes_outlined, Colors.purple),
                                      const SizedBox(height: 8),
                                      _auditSummaryCard('Target Load', report.targetDomains, Icons.checklist_outlined, Colors.teal),
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    _auditSummaryCard('Student Age', '${report.age} Years', Icons.person_outline, Colors.blue),
                                    const SizedBox(width: 12),
                                    _auditSummaryCard('Mastery Criteria', '80% across 3 days', Icons.track_changes_outlined, Colors.purple),
                                    const SizedBox(width: 12),
                                    _auditSummaryCard('Target Load', report.targetDomains, Icons.checklist_outlined, Colors.teal),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // Proposed Goals & Target Breakdown
                            const Text('Clinical Objectives & Target Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                            const SizedBox(height: 10),
                            _buildTargetRow('Manding', 'Spontaneous vocal manding for 20 distinct missing items without prompting.', 'Mastered 6/20'),
                            _buildTargetRow('Tacting', 'Tact 50 community items and common objects in natural environment.', 'Mastered 32/50'),
                            _buildTargetRow('Echoic Skills', 'Repeat 3-syllable functional phrases with 90% consonant-vowel clarity.', 'Baseline: 40%'),
                            _buildTargetRow('Behavior Intervention Plan (BIP)', 'Reduce task-refusal elopement via functional communication training (FCT).', 'Target: < 2 daily'),

                            const SizedBox(height: 20),
                            // Director Review Notes
                            const Text('Clinical Director Review & Supervision Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Enter clinical observations, prompt hierarchy adjustments, or notes for the therapist...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Digital Signature Stamp Preview
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBF8FE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                    ),
                                    child: const Icon(Icons.draw, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Clinical Director Authorization Stamp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                        Text('BCBA-D Board Certified Behavior Analyst • Ray of Hope Center for Autism', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.primary),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: const Text('Dr. Vincent Sterling, BCBA-D ✍️', style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 24, color: AppColors.divider),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.replay, color: AppColors.statusDeactivated, size: 18),
                          label: const Text('Request Revision', style: TextStyle(color: AppColors.statusDeactivated, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.statusDeactivated),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            setState(() {
                              report.status = IepStatus.returned;
                              report.directorNotes = notesController.text.trim().isNotEmpty
                                  ? notesController.text.trim()
                                  : 'Clinical revisions requested by Director.';
                            });
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('IEP for ${report.studentName} returned to therapist for revisions.'),
                                backgroundColor: AppColors.statusDeactivated,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.verified, color: Colors.white, size: 18),
                          label: const Text('Sign & Clinically Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            setState(() {
                              report.status = IepStatus.approved;
                              report.signDate = '10-09-2026';
                              report.directorNotes = notesController.text.trim();
                            });
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('IEP for ${report.studentName} clinically approved & signed!'),
                                backgroundColor: AppColors.statusActive,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _auditSummaryCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(val, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetRow(String domain, String description, String progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(domain, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.divider)),
            child: Text(progress, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _reports.where((r) => r.status == IepStatus.pending).length;
    final approvedCount = _reports.where((r) => r.status == IepStatus.approved).length;
    final returnedCount = _reports.where((r) => r.status == IepStatus.returned).length;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Responsive LayoutBuilder)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              const titleCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clinical Approvals & IEP Sign-Off Portal',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Review, audit, and provide BCBA-D digital sign-off for student individualized education plans.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              );

              final exportBtn = ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 16),
                label: const Text('Export Clinical Audit', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating comprehensive clinical audit report PDF...')),
                  );
                },
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleCol,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: exportBtn),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(child: titleCol),
                  const SizedBox(width: 16),
                  exportBtn,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Pipeline Filter Tabs + Search bar (Responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 750;
              final tabs = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPipelineTab(0, 'All Reports (${_reports.length})', null),
                    const SizedBox(width: 8),
                    _buildPipelineTab(1, 'Pending Audit ($pendingCount)', AppColors.statusPending),
                    const SizedBox(width: 8),
                    _buildPipelineTab(2, 'Approved ($approvedCount)', AppColors.statusActive),
                    const SizedBox(width: 8),
                    _buildPipelineTab(3, 'Revision Needed ($returnedCount)', AppColors.statusDeactivated),
                  ],
                ),
              );

              final searchBox = Container(
                width: isNarrow ? double.infinity : 240,
                height: 38,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: const InputDecoration(
                          hintText: 'Search student or therapist...',
                          hintStyle: TextStyle(fontSize: 12, color: AppColors.textHint),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const Icon(Icons.search, color: AppColors.textHint, size: 18),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchBox,
                    const SizedBox(height: 12),
                    tabs,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: tabs),
                  const SizedBox(width: 12),
                  searchBox,
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Main Table Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: constraints.maxWidth < 750 ? 750 : constraints.maxWidth,
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(width: 50, child: Text('Photo', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold, fontSize: 13))),
                                Expanded(flex: 2, child: Text('Student Name', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold, fontSize: 13))),
                                Expanded(flex: 2, child: Text('Assigned Clinician', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold, fontSize: 13))),
                                Expanded(flex: 2, child: Text('Program Cycle', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold, fontSize: 13))),
                                Expanded(flex: 3, child: Text('Target Objectives', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold, fontSize: 13))),
                                Expanded(flex: 2, child: Text('Status', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold, fontSize: 13))),
                                SizedBox(width: 110, child: Text('Action', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                              ],
                            ),
                          ),

                          // Table Rows
                          Expanded(
                            child: _filteredReports.isEmpty
                                ? const Center(
                                    child: Text('No IEP reports match your current filter.', style: TextStyle(color: AppColors.textSecondary)),
                                  )
                                : ListView.separated(
                                    itemCount: _filteredReports.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                                    itemBuilder: (ctx, i) {
                                      final item = _filteredReports[i];
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        color: i % 2 == 0 ? Colors.white : const Color(0xFFFAF7FC),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 50,
                                              child: CircleAvatar(
                                                radius: 18,
                                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                                child: Text(
                                                  item.studentName.substring(0, 1),
                                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                                  Text('Age: ${item.age} yrs • Sub: ${item.submittedDate}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(item.therapistName, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(item.cycle, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(item.targetDomains, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(color: item.status.bgColor, borderRadius: BorderRadius.circular(12)),
                                                  child: Text(
                                                    item.status.label,
                                                    style: TextStyle(color: item.status.color, fontWeight: FontWeight.bold, fontSize: 11),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 110,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: item.status == IepStatus.pending ? AppColors.primary : Colors.grey.shade100,
                                                      foregroundColor: item.status == IepStatus.pending ? Colors.white : AppColors.textPrimary,
                                                      elevation: 0,
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                        side: BorderSide(color: item.status == IepStatus.pending ? AppColors.primary : AppColors.divider),
                                                      ),
                                                    ),
                                                    onPressed: () => _openAuditDialog(item),
                                                    child: Text(
                                                      item.status == IepStatus.pending ? 'Audit & Sign' : 'Review',
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.status == IepStatus.pending ? Colors.white : AppColors.primary),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          // Pagination Footer
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(top: BorderSide(color: AppColors.divider)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Showing ${_filteredReports.length} of ${_reports.length} IEP reports', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: null,
                                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                                      child: const Text('Previous', style: TextStyle(fontSize: 11)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                                      child: const Center(child: Text('1', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: null,
                                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                                      child: const Text('Next', style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineTab(int index, String label, Color? highlightColor) {
    final isSelected = _selectedFilterIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilterIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (highlightColor ?? AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

