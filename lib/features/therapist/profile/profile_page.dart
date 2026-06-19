// lib/features/therapist/profile/profile_page.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/coming_soon_page.dart';

class TherapistProfilePage extends StatelessWidget {
  const TherapistProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(title: 'Profile', icon: Icons.person_outline);
  }
}
