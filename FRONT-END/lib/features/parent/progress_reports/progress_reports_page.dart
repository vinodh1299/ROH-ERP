// lib/features/parent/progress_reports/progress_reports_page.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/coming_soon_page.dart';

class ProgressReportsPage extends StatelessWidget {
  const ProgressReportsPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const ComingSoonPage(title: 'Progress Reports', icon: Icons.bar_chart_outlined);
}
