// lib/features/director/students_section/students_section_page.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/coming_soon_page.dart';

class StudentsSectionPage extends StatelessWidget {
  const StudentsSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(
      title: 'Students',
      icon: Icons.people_outline,
    );
  }
}
