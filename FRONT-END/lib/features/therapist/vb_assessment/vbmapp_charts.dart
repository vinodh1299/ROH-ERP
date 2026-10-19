import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'milestone_matrix.dart';

/// Charts shared by the VB-MAPP Barriers, Transition and report pages.

const vbTestLabels = ['1ST', '2ND', '3RD', '4TH'];

String formatVbScore(num v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// One barrier: columns are tests 1–4, rows are ratings 4 (top) to 1, filled
/// up to that test's score. A score of 0 fills nothing, so the footer shows
/// each test's number (or '–' when that test did not score the barrier).
class BarrierMiniChart extends StatelessWidget {
  final String title;
  final String barrierKey;
  final Map<int, Map<String, int>> scoresPerTest;

  const BarrierMiniChart({
    super.key,
    required this.title,
    required this.barrierKey,
    required this.scoresPerTest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textPrimary, width: 1.5),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth = constraints.maxWidth / 4;
                final cellHeight = constraints.maxHeight / 4;
                return Column(
                  children: List.generate(4, (rowIndex) {
                    final rating =
                        4 - rowIndex; // 4 at the top, 1 at the bottom
                    return Row(
                      children: List.generate(4, (colIndex) {
                        final test = colIndex + 1;
                        final score = scoresPerTest[test]?[barrierKey];
                        final filled = score != null && score >= rating;
                        return Container(
                          width: cellWidth,
                          height: cellHeight,
                          decoration: BoxDecoration(
                            color: filled
                                ? milestoneTestColors[test]
                                : Colors.transparent,
                            border: Border.all(
                                color: const Color(0xFFE5D5F5), width: 0.8),
                          ),
                        );
                      }),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (int t = 1; t <= 4; t++)
                Expanded(
                  child: Text(
                    '${scoresPerTest[t]?[barrierKey] ?? '–'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Vertical bars of a total score for tests 1–4 (null = test not done).
class TestTotalsChart extends StatelessWidget {
  final String title;
  final Map<int, double?> totals;
  final double maxScore;
  final String? subtitle;

  const TestTotalsChart({
    super.key,
    required this.title,
    required this.totals,
    required this.maxScore,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int t = 1; t <= 4; t++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: LayoutBuilder(builder: (context, c) {
                        final v = totals[t];
                        final barMax = c.maxHeight - 20;
                        final h = v == null || maxScore <= 0
                            ? 0.0
                            : (v / maxScore).clamp(0.0, 1.0) * barMax;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              v == null ? '–' : formatVbScore(v),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: h,
                              constraints: const BoxConstraints(maxWidth: 56),
                              decoration: BoxDecoration(
                                color: milestoneTestColors[t],
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            children: [
              for (int t = 1; t <= 4; t++)
                Expanded(
                  child: Text(
                    '${vbTestLabels[t - 1]} test',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Maximum ${formatVbScore(maxScore)}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Coloured key of the four tests.
class TestColorKey extends StatelessWidget {
  const TestColorKey({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (int t = 1; t <= 4; t++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: milestoneTestColors[t],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text('${vbTestLabels[t - 1]} test',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
      ],
    );
  }
}
