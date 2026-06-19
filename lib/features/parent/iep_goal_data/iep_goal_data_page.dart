// lib/features/parent/iep_goal_data/iep_goal_data_page.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/coming_soon_page.dart';

class IepGoalDataPage extends StatelessWidget {
  const IepGoalDataPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const ComingSoonPage(title: 'IEP Goal Data', icon: Icons.assignment_outlined);
}
