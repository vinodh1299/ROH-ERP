// lib/features/director/iep_reports_section/iep_reports_section_page.dart
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'package:roh_erp/core/layout/responsive.dart';
import 'package:roh_erp/core/services/report_pdf.dart';
import 'package:roh_erp/core/widgets/edit_record_dialogs.dart';

enum IepStatus {
  pending('Pending Audit', AppColors.statusPending, AppColors.statusPendingBg),
  approved(
      'Approved & Active', AppColors.statusActive, AppColors.statusActiveBg),
  returned('Revision Needed', AppColors.statusDeactivated,
      AppColors.statusDeactivatedBg);

  final String label;
  final Color color;
  final Color bgColor;
  const IepStatus(this.label, this.color, this.bgColor);
}

class IepReportItem {
  final String id;

  /// Numeric `iep_reports.id` used by the sign-off / revision actions.
  final int dbId;
  final String title;
  final String signedBy;
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
    required this.dbId,
    this.title = '',
    this.signedBy = '',
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
  List<IepReportItem> _reports = [];
  bool _isLoading = true;
  int _page = 0;
  static const int _pageSize = 10;

  // Governance values shown in the audit dialog (get_governance_settings).
  String _masteryCriteria = '80% across 3 consecutive sessions';
  String _signatureName = 'Clinical Director, BCBA-D';

  @override
  void initState() {
    super.initState();
    _loadIepReports();
  }

  Future<void> _loadGovernance() async {
    final g = await ApiService().get('get_governance_settings');
    if (!mounted || g is! Map || g['error'] != null) return;
    setState(() {
      final mastery = (g['target_mastery_criteria'] ?? '').toString().trim();
      if (mastery.isNotEmpty) _masteryCriteria = mastery;
      final name = (g['director_signature_name'] ?? '').toString().trim();
      final title = (g['director_title'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        _signatureName = title.isNotEmpty ? '$name, $title' : name;
      }
    });
  }

  Future<void> _loadIepReports() async {
    _loadGovernance();
    try {
      final res = await ApiService().get('get_iep_reports');
      if (res is List) {
        final items = res.map((r) {
          final id = 'IEP-${r['id']}';
          final sName = r['student_name'] ?? 'Student';
          final tName = r['therapist_name'] ?? 'Clinician';
          final cycle = r['cycle_term'] ?? 'Q3 2026 Treatment Plan';
          final goals =
              r['goals_summary'] ?? 'Clinical Protocol & Behavioral Milestones';
          final subDate = r['created_at'] != null
              ? r['created_at'].toString().split('T')[0]
              : '—';
          final statusStr =
              (r['status'] ?? 'Pending Approval').toString().toLowerCase();

          IepStatus status;
          if (statusStr.contains('active') || statusStr.contains('approved')) {
            status = IepStatus.approved;
          } else if (statusStr.contains('return') ||
              statusStr.contains('revision')) {
            status = IepStatus.returned;
          } else {
            status = IepStatus.pending;
          }

          return IepReportItem(
            id: id,
            dbId: int.tryParse('${r['id']}') ?? 0,
            title: (r['title'] ?? '').toString(),
            signedBy: (r['director_signer_name'] ?? '').toString(),
            studentName: sName,
            age: _ageFromDob(r['student_dob']),
            therapistName: tName,
            cycle: cycle,
            targetDomains: goals,
            submittedDate: subDate,
            status: status,
            directorNotes: r['director_notes'],
            signDate: r['director_signed_at'] != null
                ? r['director_signed_at'].toString().split('T')[0]
                : null,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _reports = items;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<IepReportItem> get _filteredReports {
    return _reports.where((item) {
      if (_selectedFilterIndex == 1 && item.status != IepStatus.pending)
        return false;
      if (_selectedFilterIndex == 2 && item.status != IepStatus.approved)
        return false;
      if (_selectedFilterIndex == 3 && item.status != IepStatus.returned)
        return false;
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

  int get _pageCount {
    final n = _filteredReports.length;
    return n == 0 ? 1 : (n / _pageSize).ceil();
  }

  /// The slice of [_filteredReports] on the current page.
  List<IepReportItem> get _pagedReports {
    final all = _filteredReports;
    final page = _page.clamp(0, _pageCount - 1);
    final start = page * _pageSize;
    final end = (start + _pageSize).clamp(0, all.length);
    return start >= all.length ? const [] : all.sublist(start, end);
  }

  String get _showingLabel {
    final total = _filteredReports.length;
    if (total == 0) return 'Showing 0 of ${_reports.length} IEP reports';
    final page = _page.clamp(0, _pageCount - 1);
    final start = page * _pageSize + 1;
    final end = (start + _pageSize - 1).clamp(0, total);
    return 'Showing $start–$end of $total IEP reports';
  }

  Future<void> _exportAudit() async {
    final reports = _filteredReports;
    if (reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No IEP reports match the current filter.')));
      return;
    }
    const filters = [
      'All Reports',
      'Pending Audit',
      'Approved',
      'Revision Needed'
    ];
    final subtitle = [
      'Filter: ${filters[_selectedFilterIndex]}',
      if (_searchQuery.trim().isNotEmpty) 'Search: "${_searchQuery.trim()}"',
      '${reports.length} report(s)',
    ].join(' • ');
    await ReportPdf.share(
      title: 'Clinical IEP Audit',
      subtitle: subtitle,
      fileName: 'clinical_iep_audit.pdf',
      sections: [
        ReportSection(
          'IEP Reports',
          columns: const [
            'Student',
            'Therapist',
            'Title / Cycle',
            'Status',
            'Created',
            'Signed by'
          ],
          rows: [
            for (final r in reports)
              [
                r.studentName,
                r.therapistName,
                r.title.isNotEmpty ? '${r.title} (${r.cycle})' : r.cycle,
                r.status.label,
                r.submittedDate,
                r.signedBy.isNotEmpty
                    ? '${r.signedBy}${r.signDate != null ? ' on ${r.signDate}' : ''}'
                    : '—',
              ],
          ],
        ),
      ],
    );
  }

  Widget _buildPaginationBtn(
      String text, bool isSelected, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null && !isSelected ? 0.4 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Previous / page numbers / Next; hidden when everything fits on one page.
  Widget _buildPagination() {
    final count = _pageCount;
    if (count <= 1) return const SizedBox.shrink();
    final page = _page.clamp(0, count - 1);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPaginationBtn('Previous', false,
              page > 0 ? () => setState(() => _page = page - 1) : null),
          for (int i = 0; i < count; i++)
            _buildPaginationBtn(
                '${i + 1}', i == page, () => setState(() => _page = i)),
          _buildPaginationBtn('Next', false,
              page < count - 1 ? () => setState(() => _page = page + 1) : null),
        ],
      ),
    );
  }

  void _openAuditDialog(IepReportItem report) {
    final notesController =
        TextEditingController(text: report.directorNotes ?? '');
    String? notesError;
    bool busy = false;

    showDialog(
      context: context,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isPhone = screenWidth < Breakpoints.compact;
            return Dialog(
              insetPadding: isPhone
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 24)
                  : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                          child: const Icon(Icons.verified_user_outlined,
                              color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clinical Director IEP Audit: ${report.studentName}',
                                style: TextStyle(
                                    fontSize: screenWidth < 600 ? 15 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary),
                              ),
                              Text(
                                'Program Cycle: ${report.cycle} | Submitted by: ${report.therapistName}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                              if (isPhone) ...[
                                const SizedBox(height: 6),
                                _statusChip(report.status),
                              ],
                            ],
                          ),
                        ),
                        if (!isPhone) _statusChip(report.status),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: AppColors.textHint),
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
                                      _auditSummaryCard(
                                          'Student Age',
                                          '${report.age} Years',
                                          Icons.person_outline,
                                          Colors.blue),
                                      const SizedBox(height: 8),
                                      _auditSummaryCard(
                                          'Mastery Criteria',
                                          _masteryCriteria,
                                          Icons.track_changes_outlined,
                                          Colors.purple),
                                      const SizedBox(height: 8),
                                      _auditSummaryCard(
                                          'Target Load',
                                          report.targetDomains,
                                          Icons.checklist_outlined,
                                          Colors.teal),
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    _auditSummaryCard(
                                        'Student Age',
                                        '${report.age} Years',
                                        Icons.person_outline,
                                        Colors.blue),
                                    const SizedBox(width: 12),
                                    _auditSummaryCard(
                                        'Mastery Criteria',
                                        _masteryCriteria,
                                        Icons.track_changes_outlined,
                                        Colors.purple),
                                    const SizedBox(width: 12),
                                    _auditSummaryCard(
                                        'Target Load',
                                        report.targetDomains,
                                        Icons.checklist_outlined,
                                        Colors.teal),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // Proposed Goals & Target Breakdown
                            const Text('Clinical Objectives & Target Breakdown',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary)),
                            _buildTargetRow('Treatment Focus',
                                report.targetDomains, 'Assigned Targets'),
                            _buildTargetRow('Reporting Cycle', report.cycle,
                                report.status.label),

                            const SizedBox(height: 20),
                            // Director Review Notes
                            const Text(
                                'Clinical Director Review & Supervision Notes',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: notesController,
                              maxLines: 3,
                              onChanged: (_) {
                                if (notesError != null) {
                                  setDialogState(() => notesError = null);
                                }
                              },
                              decoration: InputDecoration(
                                errorText: notesError,
                                hintText:
                                    'Enter clinical observations, prompt hierarchy adjustments, or notes for the therapist...',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: AppColors.divider)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary)),
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
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                    ),
                                    child: const Icon(Icons.draw,
                                        color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Clinical Director Authorization Stamp',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: AppColors.textPrimary)),
                                        Text(
                                            'BCBA-D Board Certified Behavior Analyst • Ray of Hope Center for Autism',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: AppColors.primary),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: Text('$_signatureName ✍️',
                                        style: const TextStyle(
                                            fontFamily: 'serif',
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary)),
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
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.replay,
                                color: AppColors.statusDeactivated, size: 18),
                            label: const Text('Request Revision',
                                style: TextStyle(
                                    color: AppColors.statusDeactivated,
                                    fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.statusDeactivated),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: busy
                                ? null
                                : () async {
                                    final notes = notesController.text.trim();
                                    if (notes.isEmpty) {
                                      setDialogState(() => notesError =
                                          'Add notes telling the therapist what to revise.');
                                      return;
                                    }
                                    setDialogState(() => busy = true);
                                    final res = await ApiService()
                                        .post('request_iep_revision', {
                                      'iep_id': report.dbId,
                                      'director_notes': notes,
                                    });
                                    if (!mounted) return;
                                    final ok = showApiResult(this.context, res,
                                        'IEP for ${report.studentName} returned to therapist for revisions.');
                                    if (ok) {
                                      if (ctx.mounted) Navigator.of(ctx).pop();
                                      _loadIepReports();
                                    } else {
                                      setDialogState(() => busy = false);
                                    }
                                  },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.verified,
                                color: Colors.white, size: 18),
                            label: const Text('Sign & Clinically Approve',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: busy
                                ? null
                                : () async {
                                    final notes = notesController.text.trim();
                                    setDialogState(() => busy = true);
                                    final res = await ApiService()
                                        .post('sign_off_iep', {
                                      'iep_id': report.dbId,
                                      'director_notes': notes,
                                    });
                                    if (!mounted) return;
                                    final ok = showApiResult(this.context, res,
                                        'IEP for ${report.studentName} clinically approved & signed!');
                                    if (ok) {
                                      if (ctx.mounted) Navigator.of(ctx).pop();
                                      _loadIepReports();
                                    } else {
                                      setDialogState(() => busy = false);
                                    }
                                  },
                          ),
                        ],
                      ),
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

  Widget _auditSummaryCard(
      String title, String val, IconData icon, Color color) {
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
                  Text(title,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(val,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetRow(String domain, String description, String progress) {
    final progressChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.divider)),
      child: Text(progress,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
    );
    final isPhone = Breakpoints.isCompact(context);
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
            child: Text(domain,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11),
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
          if (isPhone)
            // Phone: stack the progress chip under the description so the
            // text column keeps a readable width.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  progressChip,
                ],
              ),
            )
          else ...[
            Expanded(
              child: Text(description,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary)),
            ),
            const SizedBox(width: 12),
            progressChip,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        _reports.where((r) => r.status == IepStatus.pending).length;
    final approvedCount =
        _reports.where((r) => r.status == IepStatus.approved).length;
    final returnedCount =
        _reports.where((r) => r.status == IepStatus.returned).length;

    return Padding(
      padding: Breakpoints.pagePadding(context),
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
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Review, audit, and provide BCBA-D digital sign-off for student individualized education plans.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              );

              final exportBtn = ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf,
                    color: Colors.white, size: 16),
                label: const Text('Export Clinical Audit',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _exportAudit,
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
                    _buildPipelineTab(
                        0, 'All Reports (${_reports.length})', null),
                    const SizedBox(width: 8),
                    _buildPipelineTab(1, 'Pending Audit ($pendingCount)',
                        AppColors.statusPending),
                    const SizedBox(width: 8),
                    _buildPipelineTab(
                        2, 'Approved ($approvedCount)', AppColors.statusActive),
                    const SizedBox(width: 8),
                    _buildPipelineTab(3, 'Revision Needed ($returnedCount)',
                        AppColors.statusDeactivated),
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
                        onChanged: (val) => setState(() {
                          _searchQuery = val;
                          _page = 0;
                        }),
                        decoration: const InputDecoration(
                          hintText: 'Search student or therapist...',
                          hintStyle: TextStyle(
                              fontSize: 12, color: AppColors.textHint),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const Icon(Icons.search,
                        color: AppColors.textHint, size: 18),
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
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Phone: one card per report instead of a 7-column table.
                        if (constraints.maxWidth < Breakpoints.compact) {
                          return _buildReportCards();
                        }
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: constraints.maxWidth < 750
                                ? 750
                                : constraints.maxWidth,
                            child: Column(
                              children: [
                                // Table Header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 14),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                  ),
                                  child: const Row(
                                    children: [
                                      SizedBox(
                                          width: 50,
                                          child: Text('Photo',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.tableHeaderText,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13))),
                                      Expanded(
                                          flex: 2,
                                          child: Text('Student Name',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.tableHeaderText,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13))),
                                      Expanded(
                                          flex: 2,
                                          child: Text('Assigned Clinician',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.tableHeaderText,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13))),
                                      Expanded(
                                          flex: 2,
                                          child: Text('Program Cycle',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.tableHeaderText,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13))),
                                      Expanded(
                                          flex: 3,
                                          child: Text('Target Objectives',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.tableHeaderText,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13))),
                                      Expanded(
                                          flex: 2,
                                          child: Text('Status',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.tableHeaderText,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13))),
                                      SizedBox(
                                          width: 110,
                                          child: Text('Action',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.tableHeaderText,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13),
                                              textAlign: TextAlign.center)),
                                    ],
                                  ),
                                ),

                                // Table Rows
                                Expanded(
                                  child: _filteredReports.isEmpty
                                      ? const Center(
                                          child: Text(
                                              'No IEP reports match your current filter.',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary)),
                                        )
                                      : ListView.separated(
                                          itemCount: _pagedReports.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(
                                                  height: 1,
                                                  color: AppColors.divider),
                                          itemBuilder: (ctx, i) {
                                            final item = _pagedReports[i];
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 12),
                                              color: i % 2 == 0
                                                  ? Colors.white
                                                  : const Color(0xFFFAF7FC),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 50,
                                                    child: CircleAvatar(
                                                      radius: 18,
                                                      backgroundColor: AppColors
                                                          .primary
                                                          .withValues(
                                                              alpha: 0.1),
                                                      child: Text(
                                                        item.studentName
                                                            .substring(0, 1),
                                                        style: const TextStyle(
                                                            color: AppColors
                                                                .primary,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(item.studentName,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 13,
                                                                color: AppColors
                                                                    .textPrimary)),
                                                        Text(
                                                            'Age: ${item.age} yrs • Sub: ${item.submittedDate}',
                                                            style: const TextStyle(
                                                                fontSize: 11,
                                                                color: AppColors
                                                                    .textSecondary)),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                        item.therapistName,
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: AppColors
                                                                .textPrimary)),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(item.cycle,
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: AppColors
                                                                .textPrimary)),
                                                  ),
                                                  Expanded(
                                                    flex: 3,
                                                    child: Text(
                                                        item.targetDomains,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            color: AppColors
                                                                .textSecondary)),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: _statusChip(
                                                          item.status),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 110,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        _actionButton(item),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                        top: BorderSide(
                                            color: AppColors.divider)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_showingLabel,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary)),
                                      const SizedBox(width: 12),
                                      Flexible(child: _buildPagination()),
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

  Widget _statusChip(IepStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: status.bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.label,
        style: TextStyle(
            color: status.color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _actionButton(IepReportItem item) {
    final isPending = item.status == IepStatus.pending;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isPending ? AppColors.primary : Colors.grey.shade100,
        foregroundColor: isPending ? Colors.white : AppColors.textPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: isPending ? AppColors.primary : AppColors.divider),
        ),
      ),
      onPressed: () => _openAuditDialog(item),
      child: Text(
        isPending ? 'Audit & Sign' : 'Review',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isPending ? Colors.white : AppColors.primary),
      ),
    );
  }

  /// Phone layout of the report list: a stacked card per IEP report showing
  /// student, clinician, cycle, objectives, status and the action button.
  Widget _buildReportCards() {
    return Column(
      children: [
        Expanded(
          child: _filteredReports.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No IEP reports match your current filter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _pagedReports.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (ctx, i) {
                    final item = _pagedReports[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      color:
                          i % 2 == 0 ? Colors.white : const Color(0xFFFAF7FC),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  item.studentName.substring(0, 1),
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.studentName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppColors.textPrimary)),
                                    Text(
                                        'Age: ${item.age} yrs • Sub: ${item.submittedDate}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _cardField('Assigned Clinician', item.therapistName),
                          _cardField('Program Cycle', item.cycle),
                          _cardField('Target Objectives', item.targetDomains),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Flexible(child: _statusChip(item.status)),
                              const SizedBox(width: 8),
                              const Spacer(),
                              _actionButton(item),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_showingLabel,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              if (_pageCount > 1) ...[
                const SizedBox(height: 8),
                _buildPagination(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tableHeaderText)),
          ),
          Expanded(
            child: Text(value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineTab(int index, String label, Color? highlightColor) {
    final isSelected = _selectedFilterIndex == index;
    return InkWell(
      onTap: () => setState(() {
        _selectedFilterIndex = index;
        _page = 0;
      }),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (highlightColor ?? AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Whole years since [dob] (e.g. "2019-11-21"); 0 when missing or unreadable.
int _ageFromDob(dynamic dob) {
  final d = DateTime.tryParse((dob ?? '').toString());
  if (d == null) return 0;
  final now = DateTime.now();
  var age = now.year - d.year;
  if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
  return age < 0 ? 0 : age;
}
