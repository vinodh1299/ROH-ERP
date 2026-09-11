import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import 'package:roh_erp/core/services/api_service.dart';

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
      return sName.contains(q) || title.contains(q) || tName.contains(q) || status.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Students IEP Reports', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              final entriesSelector = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Show', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white,
                    ),
                    child: Text('${_reports.length}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  const Text('entries', style: TextStyle(color: AppColors.textSecondary)),
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
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: const InputDecoration(hintText: 'Search IEPs...', border: InputBorder.none, isDense: true),
                      ),
                    ),
                    const Icon(Icons.search, color: AppColors.textHint, size: 20),
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
                            const Icon(Icons.error_outline, color: AppColors.statusDeactivated, size: 40),
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadReports, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _filteredReports.isEmpty
                        ? const Center(
                            child: Text('No IEP reports found in database.', style: TextStyle(color: AppColors.textSecondary)),
                          )
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
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFD6BFDC),
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Expanded(flex: 1, child: Text('Photo', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                                          Expanded(flex: 2, child: Text('Student', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                                          Expanded(flex: 2, child: Text('Therapist', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                                          Expanded(flex: 2, child: Text('Cycle / Term', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                                          Expanded(flex: 2, child: Row(children: [Text('Status', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold)), Icon(Icons.unfold_more, size: 16, color: AppColors.tableHeaderText)])),
                                          Expanded(flex: 1, child: Text('Action', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _filteredReports.length,
                                        itemBuilder: (context, index) {
                                          final report = _filteredReports[index];
                                          final studentName = report['student_name'] ?? 'Student';
                                          final therapistName = report['therapist_name'] ?? 'Therapist';
                                          final cycleTerm = report['cycle_term'] ?? 'Q3 2026 Plan';
                                          final status = report['status'] ?? 'Active';
                                          final isActive = status == 'Active';

                                          final badgeColor = isActive ? AppColors.statusActive : AppColors.statusPending;
                                          final badgeBg = isActive ? AppColors.statusActiveBg : AppColors.statusPendingBg;

                                          return Container(
                                            color: index % 2 == 0 ? Colors.transparent : Colors.white.withValues(alpha: 0.6),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: AppImages.studentAvatar(
                                                      width: 36,
                                                      height: 36,
                                                      borderRadius: BorderRadius.circular(18),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(flex: 2, child: Text(studentName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                                                Expanded(flex: 2, child: Text(therapistName, style: const TextStyle(color: AppColors.textSecondary))),
                                                Expanded(flex: 2, child: Text(cycleTerm, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                                                Expanded(
                                                  flex: 2,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: badgeBg,
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      child: Text(status, style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.remove_red_eye, color: AppColors.primary, size: 20),
                                                        tooltip: 'View IEP Goals',
                                                        onPressed: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (ctx) => AlertDialog(
                                                              title: Text('$studentName - Treatment Plan'),
                                                              content: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text('Title: ${report['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                                  const SizedBox(height: 8),
                                                                  Text('Goals: ${report['goals_summary'] ?? 'N/A'}'),
                                                                  const SizedBox(height: 8),
                                                                  Text('Scores: Manding ${report['manding_score']} | Tacting ${report['tacting_score']} | Listener ${report['listener_score']}'),
                                                                  const SizedBox(height: 8),
                                                                  Text('Director Notes: ${report['director_notes'] ?? 'Pending evaluation'}'),
                                                                ],
                                                              ),
                                                              actions: [
                                                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                                                              ],
                                                            ),
                                                          );
                                                        },
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
                                    Container(
                                      padding: const EdgeInsets.all(16.0),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(onPressed: () {}, child: const Text('Previous', style: TextStyle(color: AppColors.textHint))),
                                          const SizedBox(width: 8),
                                          _buildPageNum(1, true),
                                          const SizedBox(width: 8),
                                          TextButton(onPressed: () {}, child: const Text('Next', style: TextStyle(color: AppColors.primary))),
                                        ],
                                      ),
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

  Widget _buildPageNum(int num, bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        num.toString(),
        style: TextStyle(color: active ? Colors.white : AppColors.textPrimary),
      ),
    );
  }
}
