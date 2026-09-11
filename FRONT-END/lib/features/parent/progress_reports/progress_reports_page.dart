import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/services/api_service.dart';

class ProgressReportsPage extends StatefulWidget {
  const ProgressReportsPage({super.key});

  @override
  State<ProgressReportsPage> createState() => _ProgressReportsPageState();
}

class _ProgressReportsPageState extends State<ProgressReportsPage> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  String? _error;

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
      );
    }

    if (_reports.isEmpty) {
      return const Center(
        child: Text('No progress reports filed yet', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 3;
          double aspectRatio = 1.1;
          if (constraints.maxWidth < 650) {
            crossAxisCount = 1;
            aspectRatio = 1.3;
          } else if (constraints.maxWidth < 950) {
            crossAxisCount = 2;
            aspectRatio = 1.2;
          }

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: _reports.length,
            itemBuilder: (context, index) {
              final report = _reports[index];
              final studentName = report['student_name'] ?? 'Student';
              final title = report['title'] ?? 'Comprehensive Treatment Plan';
              final therapistName = report['therapist_name'] ?? 'Lead BCBA';
              final status = report['status'] ?? 'Active';
              final isPending = status.toString().toLowerCase().contains('pending');
              final dateStr = report['created_at'] != null ? report['created_at'].toString().split('T')[0] : '2026-09-11';

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: const Color(0xFFF9F5FB),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primaryLight,
                                  child: const Icon(Icons.assignment_turned_in, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        studentName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                      ),
                                      Text(
                                        'Therapist: $therapistName',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scores: Manding ${report['manding_score']} | Tacting ${report['tacting_score']} | Echoic ${report['echoic_score']}',
                              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      color: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Text(
                            'Date: ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('$studentName - Treatment Plan'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Title: $title', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text('Therapist: $therapistName'),
                                      const SizedBox(height: 8),
                                      Text('Goals: ${report['goals_summary'] ?? 'N/A'}'),
                                      const SizedBox(height: 8),
                                      Text('Director Notes: ${report['director_notes'] ?? 'Pending review'}'),
                                      const SizedBox(height: 8),
                                      Text('Status: $status', style: TextStyle(color: isPending ? Colors.orange : Colors.green, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isPending ? Colors.orange : const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                isPending ? 'Pending' : 'View',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
