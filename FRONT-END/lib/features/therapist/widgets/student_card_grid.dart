import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';

class StudentCardGrid extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final VoidCallback? onStudentTap;
  final void Function(String studentName)? onStudentAction;
  final Widget? extraTopRightWidget;

  const StudentCardGrid({
    super.key,
    required this.title,
    required this.buttonLabel,
    this.onStudentTap,
    this.onStudentAction,
    this.extraTopRightWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;

            final titleWidget = Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            );

            final searchAndExtraWidget = Row(
              mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (extraTopRightWidget != null) ...[
                  extraTopRightWidget!,
                  const SizedBox(width: 16),
                ],
                Expanded(
                  flex: isNarrow ? 1 : 0,
                  child: Container(
                    width: isNarrow ? double.infinity : 250,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(Icons.search, color: AppColors.textHint, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              ],
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  const SizedBox(height: 12),
                  searchAndExtraWidget,
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: titleWidget),
                const SizedBox(width: 16),
                searchAndExtraWidget,
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 6;
              double aspectRatio = 0.85;
              if (constraints.maxWidth < 1200) crossAxisCount = 4;
              if (constraints.maxWidth < 800) crossAxisCount = 3;
              if (constraints.maxWidth < 600) crossAxisCount = 2;
              if (constraints.maxWidth < 450) {
                crossAxisCount = 1;
                aspectRatio = 1.6;
              }

              return GridView.builder(
                itemCount: 20, // Dummy data count
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, index) {
                  return Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (onStudentAction != null) {
                          onStudentAction!('Alex Thomas Sam');
                        } else if (onStudentTap != null) {
                          onStudentTap!();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF3E8FF), Color(0xFFFFE4E6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppImages.studentAvatar(
                              width: 64,
                              height: 64,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Alex Thomas Sam',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Age : 15',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 64,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                buttonLabel,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
