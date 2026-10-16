// lib/core/layout/responsive.dart
// Shared screen-size breakpoints and small layout helpers so every page
// adapts the same way on phone, tablet and desktop.
import 'package:flutter/material.dart';

enum ScreenSize { compact, medium, expanded }

class Breakpoints {
  Breakpoints._();

  /// Below this: phone layouts (single column, stacked headers, bottom nav).
  static const double compact = 600;

  /// At or above this: desktop layouts (persistent sidebar, multi-column).
  static const double expanded = 1024;

  static ScreenSize ofWidth(double width) {
    if (width < compact) return ScreenSize.compact;
    if (width < expanded) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  static ScreenSize of(BuildContext context) =>
      ofWidth(MediaQuery.sizeOf(context).width);

  static bool isCompact(BuildContext context) =>
      of(context) == ScreenSize.compact;
  static bool isExpanded(BuildContext context) =>
      of(context) == ScreenSize.expanded;

  /// Page padding that tightens on small screens.
  static EdgeInsets pagePadding(BuildContext context) => switch (of(context)) {
        ScreenSize.compact => const EdgeInsets.all(12),
        ScreenSize.medium => const EdgeInsets.all(20),
        ScreenSize.expanded => const EdgeInsets.all(24),
      };
}

/// Lets wide content (tables, score grids, charts) keep a readable minimum
/// width and scroll sideways when the available space is narrower, instead of
/// squeezing columns into one-character-wide strips.
class ScrollableMinWidth extends StatelessWidget {
  final double minWidth;
  final Widget child;

  const ScrollableMinWidth(
      {super.key, required this.minWidth, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || constraints.maxWidth >= minWidth) {
          return child;
        }
        return Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: minWidth, child: child),
          ),
        );
      },
    );
  }
}
