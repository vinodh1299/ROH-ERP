// lib/features/director/iep_reports_section/iep_reports_section_page.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/coming_soon_page.dart';

class IepReportsSectionPage extends StatelessWidget {
  const IepReportsSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(
      title: 'IEP Reports',
      icon: Icons.assignment_outlined,
    );
  }
}
