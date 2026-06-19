// lib/features/parent/profile/profile_page.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/coming_soon_page.dart';

class ParentProfilePage extends StatelessWidget {
  const ParentProfilePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const ComingSoonPage(title: 'Profile', icon: Icons.person_outline);
}
