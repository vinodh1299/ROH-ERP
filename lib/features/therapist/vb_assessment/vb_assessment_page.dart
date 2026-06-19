// lib/features/therapist/vb_assessment/vb_assessment_page.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/coming_soon_page.dart';

class VbAssessmentPage extends StatelessWidget {
  const VbAssessmentPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(title: 'VB Assessment', icon: Icons.assessment_outlined);
  }
}
