// lib/features/therapist/iep/iep_page.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/coming_soon_page.dart';

class TherapistIepPage extends StatelessWidget {
  const TherapistIepPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(title: 'IEP', icon: Icons.assignment_outlined);
  }
}
