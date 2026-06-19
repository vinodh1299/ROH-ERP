// lib/features/therapist/daily_data_sheet/daily_data_sheet_page.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/coming_soon_page.dart';

class DailyDataSheetPage extends StatelessWidget {
  const DailyDataSheetPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(title: 'Daily Data Sheet', icon: Icons.table_chart_outlined);
  }
}
