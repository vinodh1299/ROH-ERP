import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/layout/responsive.dart';
import 'package:roh_erp/features/shared_progress/progress_data.dart';
import 'package:roh_erp/features/shared_progress/student_progress_table.dart';

class AdminStudProgressPage extends StatefulWidget {
  const AdminStudProgressPage({super.key});

  @override
  State<AdminStudProgressPage> createState() => _AdminStudProgressPageState();
}

class _AdminStudProgressPageState extends State<AdminStudProgressPage> {
  ProgressData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    final data = await ProgressData.load();
    if (!mounted) return;
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final Widget content;
    if (_isLoading && data == null) {
      content = const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (data == null || !data.hasAnyData) {
      content = const ProgressEmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'No Student Progress Data Available',
        message:
            'Per-student progress will display here once therapists log daily data sheets or VB-MAPP milestone assessments.',
      );
    } else {
      content = StudentProgressTable(rows: data.studentRows());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Breakpoints.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Students Progress',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh,
                      color: AppColors.textSecondary),
                  tooltip: 'Refresh',
                  onPressed: _isLoading ? null : _load,
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }
}
