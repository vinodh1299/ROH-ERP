import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';

import 'package:roh_erp/core/constants/app_images.dart';

class AdminIepReportsPage extends StatelessWidget {
  const AdminIepReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Students IEP Reports', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              final entriesSelector = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Show', style: TextStyle(color: AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Text('10'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('entries', style: TextStyle(color: AppColors.textPrimary)),
                ],
              );

              final searchBar = Container(
                width: isNarrow ? double.infinity : 220,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Row(
                  children: [
                    Expanded(child: TextField(decoration: InputDecoration(hintText: 'Search', border: InputBorder.none, isDense: true))),
                    Icon(Icons.search, color: AppColors.textHint, size: 20),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    entriesSelector,
                    const SizedBox(height: 12),
                    searchBar,
                  ],
                );
              }

              return Row(
                children: [
                  entriesSelector,
                  const Spacer(),
                  searchBar,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 750,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8D9EC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD6BFDC),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 1, child: Text('Photo', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Name', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Row(children: [Text('Age', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold)), Icon(Icons.unfold_more, size: 16, color: AppColors.tableHeaderText)])),
                            Expanded(flex: 2, child: Text('Phone', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Row(children: [Text('Status', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold)), Icon(Icons.unfold_more, size: 16, color: AppColors.tableHeaderText)])),
                            Expanded(flex: 1, child: Text('Action', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            final statuses = ['Approved', 'Cancelled', 'Pending'];
                            final colors = [AppColors.statusActive, AppColors.statusDeactivated, AppColors.statusPending];
                            final bgColors = [AppColors.statusActiveBg, AppColors.statusDeactivatedBg, AppColors.statusPendingBg];
                            
                            final sIdx = index % 3;

                            return Container(
                              color: index % 2 == 0 ? Colors.transparent : Colors.white.withValues(alpha: 0.6),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: AppImages.studentAvatar(
                                        width: 36,
                                        height: 36,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                  ),
                                  const Expanded(flex: 2, child: Text('Matt Dickerson', style: TextStyle(color: AppColors.textPrimary))),
                                  const Expanded(flex: 1, child: Text('15', style: TextStyle(color: AppColors.textPrimary))),
                                  const Expanded(flex: 2, child: Text('xxxxxxxxxxxxx', style: TextStyle(color: AppColors.textPrimary))),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: bgColors[sIdx],
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(statuses[sIdx], style: TextStyle(color: colors[sIdx], fontSize: 12)),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Row(
                                      children: [
                                        IconButton(icon: const Icon(Icons.remove_red_eye, color: AppColors.primary, size: 20), onPressed: () {}),
                                        IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () {}),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () {}, child: const Text('Previous', style: TextStyle(color: AppColors.textHint))),
                            const SizedBox(width: 8),
                            _buildPageNum(1, true),
                            _buildPageNum(2, false),
                            _buildPageNum(3, false),
                            const SizedBox(width: 8),
                            TextButton(onPressed: () {}, child: const Text('Next', style: TextStyle(color: AppColors.primary))),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageNum(int num, bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        num.toString(),
        style: TextStyle(color: active ? Colors.white : AppColors.textPrimary),
      ),
    );
  }
}
