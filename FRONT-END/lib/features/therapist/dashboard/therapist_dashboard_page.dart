import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/schedule_service.dart';

class TherapistDashboardPage extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const TherapistDashboardPage({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    final todaySessions = scheduleService.getSessionsForTherapist('T1');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1050;

        final leftColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.welcomeGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hi, Therapist !',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back to your therapist panel.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Row (Responsive)
            LayoutBuilder(
              builder: (context, statsConstraints) {
                final isNarrow = statsConstraints.maxWidth < 450;
                final studentsCard = _buildStatCard(
                  'Total Students',
                  '250',
                  Icons.people_outline,
                  Colors.pinkAccent,
                );
                final sessionsCard = _buildStatCard(
                  'Todays Sessions',
                  todaySessions.length.toString(),
                  Icons.calendar_today_outlined,
                  AppColors.accentTeal,
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      studentsCard,
                      const SizedBox(height: 12),
                      sessionsCard,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: studentsCard),
                    const SizedBox(width: 16),
                    Expanded(child: sessionsCard),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent Activities Table Container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tabs
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      const Text(
                        'Recent Activities',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTabButton('Recent IEP Requested', true),
                          const SizedBox(width: 12),
                          _buildTabButton('Returned IEP', false),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Horizontally Scrollable Table for Zero Mobile Squishing
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 700,
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 2, child: _TableHeaderText('Name')),
                                Expanded(flex: 2, child: _TableHeaderText('Email Id')),
                                Expanded(flex: 2, child: _TableHeaderText('Phone')),
                                Expanded(flex: 1, child: _TableHeaderText('Age')),
                                Expanded(flex: 2, child: _TableHeaderText('Created Date')),
                                Expanded(flex: 2, child: _TableHeaderText('Status')),
                                Expanded(flex: 1, child: _TableHeaderText('Action')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Table Content
                          ...List.generate(5, (index) {
                            return Column(
                              children: [
                                _buildTableRow(
                                  name: 'John Doe',
                                  email: 'john.doe@example.com',
                                  phone: '+1 234 567 890',
                                  age: '12',
                                  date: '09 Sep 2026',
                                  status: index % 2 == 0 ? 'Pending' : 'Returned',
                                ),
                                if (index < 4) const Divider(color: AppColors.divider),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Pagination
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildPaginationBtn('Previous', false),
                        _buildPaginationBtn('1', true),
                        _buildPaginationBtn('2', false),
                        _buildPaginationBtn('3', false),
                        _buildPaginationBtn('4', false),
                        _buildPaginationBtn('Next', false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final rightColumn = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    "Today's Timetable",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${todaySessions.length} Sessions',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'Director-Assigned Caseload',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  if (onNavigateTab != null)
                    InkWell(
                      onTap: () => onNavigateTab!(1),
                      child: const Text(
                        'Full Schedule →',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Sessions List
              if (todaySessions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_available, size: 36, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      const Text(
                        'No sessions today',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Director has not scheduled any sessions for today yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todaySessions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                            final session = todaySessions[index];
                            final isLive = session.status == SessionStatus.inProgress;
                            final isDone = session.status == SessionStatus.completed;

                            Color statusColor = isLive
                                ? const Color(0xFF2E7D32)
                                : isDone
                                    ? Colors.grey.shade600
                                    : AppColors.primary;
                            Color statusBg = isLive
                                ? const Color(0xFFE8F5E9)
                                : isDone
                                    ? Colors.grey.shade200
                                    : AppColors.primaryLight;
                            String statusText = isLive
                                ? '● LIVE NOW'
                                : isDone
                                    ? '✓ Completed'
                                    : 'Upcoming';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isLive ? const Color(0xFFFAFFFA) : const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isLive ? const Color(0xFF4CAF50) : AppColors.divider,
                                  width: isLive ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Time & Status Row
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 13, color: statusColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${session.startTime} - ${session.endTime}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Student & Room Row
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppColors.primaryLight,
                                        child: Text(
                                          session.studentName.isNotEmpty ? session.studentName[0] : 'S',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              session.studentName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'Age: ${session.studentAge}y • ${session.room}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Program Tag
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFEEEEEE)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.psychology, size: 13, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            session.programTitle,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Action Buttons Row
                                  Row(
                                    children: [
                                      // Status toggler
                                      if (session.status == SessionStatus.upcoming)
                                        InkWell(
                                          onTap: () => scheduleService.updateSessionStatus(
                                              session.id, SessionStatus.inProgress),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: const Color(0xFF4CAF50)),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.play_arrow, size: 12, color: Color(0xFF2E7D32)),
                                                SizedBox(width: 2),
                                                Text(
                                                  'Start',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF2E7D32),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else if (session.status == SessionStatus.inProgress)
                                        InkWell(
                                          onTap: () => scheduleService.updateSessionStatus(
                                              session.id, SessionStatus.completed),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2E7D32),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.check, size: 12, color: Colors.white),
                                                SizedBox(width: 2),
                                                Text(
                                                  'Complete',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      const Spacer(),

                                      // Open Data Sheet Button
                                      InkWell(
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Opening Daily Data Sheet for ${session.studentName}...'),
                                              backgroundColor: AppColors.primary,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                          if (onNavigateTab != null) {
                                            onNavigateTab!(9); // Daily Data Sheet
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.edit_note, size: 13, color: Colors.white),
                                              SizedBox(width: 4),
                                              Text(
                                                'Data Sheet',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ],
            ),
          );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: leftColumn),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: rightColumn),
            ],
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leftColumn,
              const SizedBox(height: 24),
              rightColumn,
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTableRow({
    required String name,
    required String email,
    required String phone,
    required String age,
    required String date,
    required String status,
  }) {
    Color statusColor;
    Color statusBg;
    if (status == 'Pending') {
      statusColor = AppColors.statusPending;
      statusBg = AppColors.statusPendingBg;
    } else if (status == 'Approved') {
      statusColor = AppColors.statusActive;
      statusBg = AppColors.statusActiveBg;
    } else {
      statusColor = AppColors.statusDeactivated;
      statusBg = AppColors.statusDeactivatedBg;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(name, style: _rowTextStyle())),
          Expanded(flex: 2, child: Text(email, style: _rowTextStyle())),
          Expanded(flex: 2, child: Text(phone, style: _rowTextStyle())),
          Expanded(flex: 1, child: Text(age, style: _rowTextStyle())),
          Expanded(flex: 2, child: Text(date, style: _rowTextStyle())),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'View',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _rowTextStyle() {
    return const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      color: AppColors.textPrimary,
    );
  }

  Widget _buildPaginationBtn(String text, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  final String text;
  const _TableHeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.tableHeaderText,
      ),
    );
  }
}
