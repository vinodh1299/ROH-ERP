// lib/features/director/stud_progress_section/stud_progress_section_page.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/coming_soon_page.dart';

class StudProgressSectionPage extends StatelessWidget {
  const StudProgressSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(
      title: 'Student Progress',
      icon: Icons.trending_up_outlined,
    );
  }
}
