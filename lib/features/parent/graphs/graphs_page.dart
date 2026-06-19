// lib/features/parent/graphs/graphs_page.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/coming_soon_page.dart';

class GraphsPage extends StatelessWidget {
  const GraphsPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const ComingSoonPage(title: 'Graphs', icon: Icons.show_chart_outlined);
}
