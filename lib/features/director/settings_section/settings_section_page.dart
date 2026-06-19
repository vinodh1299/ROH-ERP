// lib/features/director/settings_section/settings_section_page.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/coming_soon_page.dart';

class SettingsSectionPage extends StatelessWidget {
  const SettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(
      title: 'Settings',
      icon: Icons.settings_outlined,
    );
  }
}
