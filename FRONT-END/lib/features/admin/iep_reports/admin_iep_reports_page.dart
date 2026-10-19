import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'package:roh_erp/core/layout/responsive.dart';

class AdminIepReportsPage extends StatefulWidget {
  const AdminIepReportsPage({super.key});

  @override
  State<AdminIepReportsPage> createState() => _AdminIepReportsPageState();
}

class _AdminIepReportsPageState extends State<AdminIepReportsPage> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  static const _pageSizes = [5, 10, 25];
  int _pageSize = 10;
  int _page = 0;

  /// null = server order, true = status A→Z, false = status Z→A.
  bool? _statusAscending;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiService().get('get_iep_reports');
      if (!mounted) return;
      if (res is List) {
        setState(() {
          _reports = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      } else if (res is Map && res['error'] != null) {
        setState(() {
          _error = res['error'].toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _reports = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredReports {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _reports;
    return _reports.where((r) {
      final sName = (r['student_name'] ?? '').toString().toLowerCase();
      final title = (r['title'] ?? '').toString().toLowerCase();
      final tName = (r['therapist_name'] ?? '').toString().toLowerCase();
      final status = (r['status'] ?? '').toString().toLowerCase();
      return sName.contains(q) ||
          title.contains(q) ||
          tName.contains(q) ||
          status.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _sortedReports {
    final list = List<Map<String, dynamic>>.from(_filteredReports);
    final asc = _statusAscending;
    if (asc != null) {
      list.sort((a, b) {
        final c = (a['status'] ?? '')
            .toString()
            .toLowerCase()
            .compareTo((b['status'] ?? '').toString().toLowerCase());
        return asc ? c : -c;
      });
    }
    return list;
  }

  int get _pageCount =>
      (_filteredReports.length / _pageSize).ceil().clamp(1, 1 << 30);

  int get _currentPage => _page.clamp(0, _pageCount - 1);

  List<Map<String, dynamic>> get _pagedReports =>
      _sortedReports.skip(_currentPage * _pageSize).take(_pageSize).toList();

  void _toggleStatusSort() {
    setState(() {
      _statusAscending = switch (_statusAscending) {
        null => true,
        true => false,
        false => null,
      };
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Breakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Students IEP Reports',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              final entriesSelector = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Show',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _pageSize,
                        isDense: true,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold),
                        items: [
                          for (final n in _pageSizes)
                            DropdownMenuItem(value: n, child: Text('$n')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _pageSize = v;
                            _page = 0;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('entries',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              );

              final searchBar = Container(
                width: isNarrow ? double.infinity : 250,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() {
                          _searchQuery = val;
                          _page = 0;
                        }),
                        decoration: const InputDecoration(
                            hintText: 'Search IEPs...',
                            border: InputBorder.none,
                            isDense: true),
                      ),
                    ),
                    const Icon(Icons.search,
                        color: AppColors.textHint, size: 20),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    entriesSelector,
                    const SizedBox(height: 12),
                    searchBar,
                  ],
                );
              }

              return Row(
                children: [
                  entriesSelector,
                  const Spacer(),
                  searchBar,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.statusDeactivated, size: 40),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: _loadReports,
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _filteredReports.isEmpty
                        ? const Center(
                            child: Text('No IEP reports found in database.',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          )
                        : Breakpoints.isCompact(context)
                            ? _buildReportCards()
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: 850,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8D9EC),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFD6BFDC),
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(16)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Expanded(
                                                  flex: 1,
                                                  child: Text('Photo',
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .tableHeaderText,
                                                          fontWeight: FontWeight
                                                              .bold))),
                                              const Expanded(
                                                  flex: 2,
                                                  child: Text('Student',
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .tableHeaderText,
                                                          fontWeight: FontWeight
                                                              .bold))),
                                              const Expanded(
                                                  flex: 2,
                                                  child: Text('Therapist',
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .tableHeaderText,
                                                          fontWeight: FontWeight
                                                              .bold))),
                                              const Expanded(
                                                  flex: 2,
                                                  child: Text('Cycle / Term',
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .tableHeaderText,
                                                          fontWeight: FontWeight
                                                              .bold))),
                                              Expanded(
                                                  flex: 2,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: InkWell(
                                                      onTap: _toggleStatusSort,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Text('Status',
                                                                style: TextStyle(
                                                                    color: AppColors
                                                                        .tableHeaderText,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            Icon(
                                                                switch (
                                                                    _statusAscending) {
                                                                  null => Icons
                                                                      .unfold_more,
                                                                  true => Icons
                                                                      .arrow_upward,
                                                                  false => Icons
                                                                      .arrow_downward,
                                                                },
                                                                size: 16,
                                                                color: AppColors
                                                                    .tableHeaderText)
                                                          ]),
                                                    ),
                                                  )),
                                              const Expanded(
                                                  flex: 1,
                                                  child: Text('Action',
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .tableHeaderText,
                                                          fontWeight: FontWeight
                                                              .bold))),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: _pagedReports.length,
                                            itemBuilder: (context, index) {
                                              final report =
                                                  _pagedReports[index];
                                              final studentName =
                                                  report['student_name'] ??
                                                      'Student';
                                              final therapistName =
                                                  report['therapist_name'] ??
                                                      'Therapist';
                                              final cycleTerm =
                                                  report['cycle_term'] ??
                                                      'Q3 2026 Plan';
                                              final status =
                                                  report['status'] ?? 'Active';
                                              final isActive =
                                                  status == 'Active';

                                              final badgeColor = isActive
                                                  ? AppColors.statusActive
                                                  : AppColors.statusPending;
                                              final badgeBg = isActive
                                                  ? AppColors.statusActiveBg
                                                  : AppColors.statusPendingBg;

                                              return Container(
                                                color: index % 2 == 0
                                                    ? Colors.transparent
                                                    : Colors.white
                                                        .withValues(alpha: 0.6),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 10),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 1,
                                                      child: Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: AppImages
                                                            .studentAvatar(
                                                          width: 36,
                                                          height: 36,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(18),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                        flex: 2,
                                                        child: Text(studentName,
                                                            style: const TextStyle(
                                                                color: AppColors
                                                                    .textPrimary,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600))),
                                                    Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                            therapistName,
                                                            style: const TextStyle(
                                                                color: AppColors
                                                                    .textSecondary))),
                                                    Expanded(
                                                        flex: 2,
                                                        child: Text(cycleTerm,
                                                            style: const TextStyle(
                                                                color: AppColors
                                                                    .textSecondary,
                                                                fontSize: 13))),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 6),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: badgeBg,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        16),
                                                          ),
                                                          child: Text(status,
                                                              style: TextStyle(
                                                                  color:
                                                                      badgeColor,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
                                                      child: Row(
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(
                                                                Icons
                                                                    .remove_red_eye,
                                                                color: AppColors
                                                                    .primary,
                                                                size: 20),
                                                            tooltip:
                                                                'View IEP Goals',
                                                            onPressed: () =>
                                                                _showIepDialog(
                                                                    report),
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
                                        if (_pageCount > 1)
                                          Container(
                                            padding: const EdgeInsets.all(16.0),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      bottom:
                                                          Radius.circular(16)),
                                            ),
                                            child: _buildPagination(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
          ),
        ],
      ),
    );
  }

  void _showIepDialog(Map<String, dynamic> report) {
    final studentName = report['student_name'] ?? 'Student';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: Breakpoints.isCompact(ctx)
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
            : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        title: Text('$studentName - Treatment Plan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title: ${report['title'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Goals: ${report['goals_summary'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text(
                  'Scores: Manding ${report['manding_score']} | Tacting ${report['tacting_score']} | Listener ${report['listener_score']}'),
              const SizedBox(height: 8),
              Text(
                  'Director Notes: ${report['director_notes'] ?? 'Pending evaluation'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  /// Phone layout: one card per IEP report (student, therapist, cycle,
  /// status chip and the view action) instead of the 6-column table.
  Widget _buildReportCards() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8D9EC),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _pagedReports.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, index) {
                final report = _pagedReports[index];
                final studentName = report['student_name'] ?? 'Student';
                final therapistName = report['therapist_name'] ?? 'Therapist';
                final cycleTerm = report['cycle_term'] ?? 'Q3 2026 Plan';
                final status = report['status'] ?? 'Active';
                final isActive = status == 'Active';
                final badgeColor =
                    isActive ? AppColors.statusActive : AppColors.statusPending;
                final badgeBg = isActive
                    ? AppColors.statusActiveBg
                    : AppColors.statusPendingBg;

                return Container(
                  color: index % 2 == 0
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.6),
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                  child: Row(
                    children: [
                      AppImages.studentAvatar(
                        width: 40,
                        height: 40,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(studentName,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(therapistName,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                            Text(cycleTerm,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(status,
                                  style: TextStyle(
                                      color: badgeColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye,
                            color: AppColors.primary, size: 20),
                        tooltip: 'View IEP Goals',
                        onPressed: () => _showIepDialog(report),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_pageCount > 1)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: _buildPagination(),
              ),
            ),
        ],
      ),
    );
  }

  /// Previous / page numbers (a window of up to 5) / Next.
  Widget _buildPagination() {
    final page = _currentPage;
    final count = _pageCount;
    final start = (page - 2).clamp(0, (count - 5).clamp(0, count));
    final end = (start + 5).clamp(0, count);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPaginationBtn('Previous', false,
            page > 0 ? () => setState(() => _page = page - 1) : null),
        for (int i = start; i < end; i++)
          _buildPaginationBtn(
              '${i + 1}', i == page, () => setState(() => _page = i)),
        _buildPaginationBtn('Next', false,
            page < count - 1 ? () => setState(() => _page = page + 1) : null),
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
                fontFamily: 'Poppins',
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
