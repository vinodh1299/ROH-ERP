// lib/features/therapist/vb_milestone/vb_milestone_page.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/coming_soon_page.dart';

class VbMilestonePage extends StatelessWidget {
  const VbMilestonePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(title: 'VB Milestone', icon: Icons.flag_outlined);
  }
}
