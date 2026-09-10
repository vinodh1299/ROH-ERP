import 'package:flutter/material.dart';
import '../widgets/student_card_grid.dart';

class VbMilestonePage extends StatelessWidget {
  const VbMilestonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentCardGrid(
      title: 'Students VB Milestone',
      buttonLabel: 'Add',
    );
  }
}
