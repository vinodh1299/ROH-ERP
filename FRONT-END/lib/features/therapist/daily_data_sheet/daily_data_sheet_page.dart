import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import '../../../core/services/offline_sync_service.dart';
import '../widgets/student_card_grid.dart';

class DailyDataSheetPage extends StatefulWidget {
  const DailyDataSheetPage({super.key});

  @override
  State<DailyDataSheetPage> createState() => _DailyDataSheetPageState();
}

class _DailyDataSheetPageState extends State<DailyDataSheetPage> {
  String? _selectedStudent;
  int _activeTab = 0;
  bool _isBarGraph = true;
  String _mandingFromDate = '08/17/2025';
  String _mandingToDate = '08/17/2025';
  String _acqFromDate = '08/17/2025';
  String _acqToDate = '08/17/2025';
  String _selectedAcqDomain = 'Manding';
  final List<String> _tabs = [
    'Manding',
    'Manding Graph',
    'Daily Data Sheet',
    'Skill Tracking Sheet',
    'Acquisition Graph',
    'ABC Data Sheet',
    'IEP Report',
  ];

  @override
  Widget build(BuildContext context) {
    if (_selectedStudent == null) {
      return StudentCardGrid(
        title: 'Students Daily Data Sheet',
        buttonLabel: 'Add',
        onStudentAction: (student) {
          setState(() {
            _selectedStudent = student;
          });
        },
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Back Button & Student Title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () => setState(() => _selectedStudent = null),
                tooltip: 'Back to students',
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 18),
                  children: [
                    TextSpan(
                      text: '$_selectedStudent ',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const TextSpan(
                      text: 'Daily Data Analysis',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Daily Data Sheet Header Banner
          _buildDailyBanner(),
          const SizedBox(height: 24),

          // Pink/Lavender Container with Tabs matching Figma THERAPIST DAILY DATA SHEET-1.png
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 560),
            decoration: BoxDecoration(
              color: const Color(0xFFE4D5EE), // Authentic soft mauve-lavender container
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tabs Bar matching Figma gradient and rounded corners
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_tabs.length, (index) => _buildTabItem(_tabs[index], index)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tab Content
                _buildActiveTabContent(),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDailyBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Photo
          AppImages.studentAvatar(
            width: 84,
            height: 84,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(width: 24),

          // Name and info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedStudent ?? 'Alex Thomas Sam',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Date of Birth : 16-02-2020',
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text(
                'Age : 13',
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
            ],
          ),
          const Spacer(),

          // Date, Time In, Time Out Fields
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBannerInputRow('Date:', '2026-03-20'),
              const SizedBox(height: 8),
              _buildBannerInputRow('Time In:', '09:30 AM'),
              const SizedBox(height: 8),
              _buildBannerInputRow('Time Out:', '01:00 PM'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerInputRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 170,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF8B25C6) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildMandingContent();
      case 1:
        return _buildMandingGraphContent();
      case 2:
        return _buildDailySheetContent();
      case 3:
        return _buildSkillTrackingContent();
      case 4:
        return _buildAcquisitionGraphContent();
      case 5:
        return _buildAbcDataSheetContent();
      case 6:
        return _buildIepDailyContent();
      default:
        return _buildMandingContent();
    }
  }

  Widget _buildMandingContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Daily Manding Records',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  await OfflineSyncService().queueTrialData({
                    'student_name': _selectedStudent,
                    'record_type': 'manding',
                    'prompted': 1,
                    'unprompted': 0,
                    'domain': 'Manding',
                    'timestamp': DateTime.now().toIso8601String(),
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Trial record queued for $_selectedStudent (Offline-ready sync active)'),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Record'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(color: AppColors.divider),
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFFF3E8FF)),
                children: [
                  Padding(padding: EdgeInsets.all(10), child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Item / Activity', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Prompt Level', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              for (int i = 1; i <= 5; i++)
                TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(10), child: Text('$i')),
                    Padding(padding: const EdgeInsets.all(10), child: Text('Water / Juice / Break / Toy #$i')),
                    const Padding(padding: EdgeInsets.all(10), child: Text('Independent (I)')),
                    Padding(padding: const EdgeInsets.all(10), child: Text('${i * 3} times')),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMandingGraphContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Filter Bar (matches Figma THERAPIST MANDING BAR GRAPH #705:5493)
        _buildMandingFilterBar(),
        const SizedBox(height: 20),

        // Manding Chart Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Manding',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              // Chart Area (either Stacked Bar or Line Chart based on _isBarGraph)
              SizedBox(
                height: 330,
                width: double.infinity,
                child: _isBarGraph
                    ? const _MandingStackedBarChart()
                    : const _MandingLineChart(),
              ),
              const SizedBox(height: 16),
              // Legend: ■ prompted mand   ■ unprompted mand
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 12, height: 12, color: const Color(0xFF4A89DC)),
                  const SizedBox(width: 6),
                  const Text(
                    'prompted mand',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 24),
                  Container(width: 12, height: 12, color: const Color(0xFFC24138)),
                  const SizedBox(width: 6),
                  const Text(
                    'unprompted mand',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Manding Data Table (matches Figma #705:5697)
        _buildMandingDataTable(),
      ],
    );
  }

  Widget _buildMandingFilterBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Wrap(
        spacing: 20,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // From Date
              const Text(
                'From Date:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins'),
              ),
              const SizedBox(width: 8),
              _buildDateInputPill(_mandingFromDate, (val) => setState(() => _mandingFromDate = val)),

              const SizedBox(width: 18),

              // To Date
              const Text(
                'To Date:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins'),
              ),
              const SizedBox(width: 8),
              _buildDateInputPill(_mandingToDate, (val) => setState(() => _mandingToDate = val)),

              const SizedBox(width: 16),

              // Search Button
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9D38CD),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
                child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),

          // Line Graph / Bar Graph Toggle Pill
          GestureDetector(
            onTap: () => setState(() => _isBarGraph = !_isBarGraph),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _isBarGraph ? const Color(0xFF4CAF50) : const Color(0xFFE4D5EE),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isBarGraph) ...[
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _isBarGraph ? 'Bar Graph' : 'Line Graph',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _isBarGraph ? Colors.white : const Color(0xFF8B25C6),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (_isBarGraph) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInputPill(String value, ValueChanged<String> onChanged) {
    return Container(
      width: 140,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF8B25C6)),
        ],
      ),
    );
  }

  Widget _buildMandingDataTable() {
    final dates = ['12-jun-19', '12-jun-19', '12-jun-19', '12-jun-19', '12-jun-19', '12-jun-19', '12-jun-19', '12-jun-19'];
    final prompted = ['24', '34', '24', '10', '16', '36', '23', '24'];
    final unprompted = ['2', '12', '6', '3', '2', '7', '2', '1'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B25C6), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(115),
            columnWidths: const {0: FixedColumnWidth(130)},
            border: TableBorder.all(
              color: const Color(0xFF8B25C6).withValues(alpha: 0.35),
              width: 1,
            ),
            children: [
              // Row 1: Date
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFFAF5FF)),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                  ),
                  ...dates.map(
                    (d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
              // Row 2: Prompted
              TableRow(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    child: Text('Prompted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                  ),
                  ...prompted.map(
                    (p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text(p, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A89DC))),
                    ),
                  ),
                ],
              ),
              // Row 3: Unprompted
              TableRow(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    child: Text('Unprompted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                  ),
                  ...unprompted.map(
                    (u) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text(u, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC24138))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailySheetContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Session Tracking Sheet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(color: AppColors.divider),
            children: const [
              TableRow(
                decoration: BoxDecoration(color: Color(0xFFF3E8FF)),
                children: [
                  Padding(padding: EdgeInsets.all(10), child: Text('Time Block', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Target Skill / Domain', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Trials / Response', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Therapist Initials', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(10), child: Text('09:30 - 10:15 AM')),
                  Padding(padding: EdgeInsets.all(10), child: Text('Listener Responding (LR Level 2)')),
                  Padding(padding: EdgeInsets.all(10), child: Text('8/10 Independent (+)')),
                  Padding(padding: EdgeInsets.all(10), child: Text('SL (Dr. Sarah Lee)')),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(10), child: Text('10:30 - 11:15 AM')),
                  Padding(padding: EdgeInsets.all(10), child: Text('Motor Imitation & Play Skills')),
                  Padding(padding: EdgeInsets.all(10), child: Text('9/10 Independent (+)')),
                  Padding(padding: EdgeInsets.all(10), child: Text('SL (Dr. Sarah Lee)')),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(10), child: Text('11:30 - 12:30 PM')),
                  Padding(padding: EdgeInsets.all(10), child: Text('EES & Tact Acquisition')),
                  Padding(padding: EdgeInsets.all(10), child: Text('7/10 Prompted (P)')),
                  Padding(padding: EdgeInsets.all(10), child: Text('SL (Dr. Sarah Lee)')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillTrackingContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skill Acquisition Tracking Sheet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(color: AppColors.divider),
            children: const [
              TableRow(
                decoration: BoxDecoration(color: Color(0xFFF3E8FF)),
                children: [
                  Padding(padding: EdgeInsets.all(10), child: Text('Program', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Target Description', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Baseline', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(10), child: Text('Mand 5M')),
                  Padding(padding: EdgeInsets.all(10), child: Text('Mands for 20 different items without prompt')),
                  Padding(padding: EdgeInsets.all(10), child: Text('4 items')),
                  Padding(padding: EdgeInsets.all(10), child: Text('In Acquisition (80%)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(10), child: Text('Tact 6M')),
                  Padding(padding: EdgeInsets.all(10), child: Text('Tacts 25 items when asked "What\'s that?"')),
                  Padding(padding: EdgeInsets.all(10), child: Text('10 items')),
                  Padding(padding: EdgeInsets.all(10), child: Text('Mastered (100%)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcquisitionGraphContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Filter Bar (matches Figma #729:4045)
        _buildAcquisitionFilterBar(),
        const SizedBox(height: 20),

        // Acquisition Chart Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Rate of Skill Acquisition - $_selectedAcqDomain',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                height: 330,
                width: double.infinity,
                child: _AcquisitionLineChart(),
              ),
              const SizedBox(height: 16),
              // Legend: ■ Cumulative Mastered Targets (Count: 26)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 12, height: 12, color: const Color(0xFF8B25C6)),
                  const SizedBox(width: 6),
                  const Text(
                    'Cumulative Mastered Targets (Count: 26)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 24),
                  Container(
                    width: 20,
                    height: 2,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Mastery Criteria Threshold (26)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Acquisition Data Table (matches Figma #729:4045 2-column table)
        _buildAcquisitionDataTable(),
      ],
    );
  }

  Widget _buildAcquisitionFilterBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Wrap(
        spacing: 20,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // From Date
              const Text(
                'From Date:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins'),
              ),
              const SizedBox(width: 8),
              _buildDateInputPill(_acqFromDate, (val) => setState(() => _acqFromDate = val)),

              const SizedBox(width: 18),

              // To Date
              const Text(
                'To Date:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins'),
              ),
              const SizedBox(width: 8),
              _buildDateInputPill(_acqToDate, (val) => setState(() => _acqToDate = val)),
            ],
          ),

          // Domain Dropdown: Manding ▼
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(19),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAcqDomain,
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8B25C6)),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedAcqDomain = val);
                },
                items: ['Manding', 'Tacting', 'Listener Responding', 'EES'].map((domain) {
                  return DropdownMenuItem<String>(
                    value: domain,
                    child: Text(domain),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcquisitionDataTable() {
    final rows = List.generate(9, (_) => const {'date': '12-jun-19', 'count': '26'});

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B25C6), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Table(
          defaultColumnWidth: const FlexColumnWidth(),
          columnWidths: const {
            0: FlexColumnWidth(2.5),
            1: FlexColumnWidth(1.5),
          },
          border: TableBorder.all(
            color: const Color(0xFF8B25C6).withValues(alpha: 0.35),
            width: 1,
          ),
          children: [
            // Header Row
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFFFAF5FF)),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  child: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  child: Text(
                    'Count',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            // Data Rows
            ...rows.map(
              (r) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    child: Text(
                      r['date']!,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    child: Text(
                      r['count']!,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8B25C6)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbcDataSheetContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ABC (Antecedent-Behavior-Consequence) Data Sheet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(color: AppColors.divider),
            children: const [
              TableRow(
                decoration: BoxDecoration(color: Color(0xFFF3E8FF)),
                children: [
                  Padding(padding: EdgeInsets.all(10), child: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Antecedent (A)', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Behavior (B)', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Consequence (C)', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Function', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(10), child: Text('20-03 10:15 AM')),
                  Padding(padding: EdgeInsets.all(10), child: Text('Task transition demand to table')),
                  Padding(padding: EdgeInsets.all(10), child: Text('Dropped to floor, vocal protest (2 min)')),
                  Padding(padding: EdgeInsets.all(10), child: Text('Wait out protest, re-present demand with prompt')),
                  Padding(padding: EdgeInsets.all(10), child: Text('Escape')),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(10), child: Text('20-03 11:45 AM')),
                  Padding(padding: EdgeInsets.all(10), child: Text('Peer playing with preferred iPad')),
                  Padding(padding: EdgeInsets.all(10), child: Text('Reached and grabbed device')),
                  Padding(padding: EdgeInsets.all(10), child: Text('Prompted to mand "My turn please" with timer')),
                  Padding(padding: EdgeInsets.all(10), child: Text('Tangible')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIepDailyContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IEP Daily Objectives Tracking',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
          ),
          SizedBox(height: 16),
          Text(
            'Target 1: Emit 20 spontaneous mands without prompts - Probes: (+, +, +, -)',
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          SizedBox(height: 8),
          Text(
            'Target 2: Tact 10 common items in classroom - Probes: (+, +, +, +)',
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          SizedBox(height: 8),
          Text(
            'Target 3: Independent sitting for 10 minutes - Probes: (+, +, -, +)',
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Manding Stacked Bar Chart Widget (matches Figma THERAPIST MANDING BAR GRAPH)
// ---------------------------------------------------------------------------
class _MandingStackedBarChart extends StatelessWidget {
  const _MandingStackedBarChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _MandingStackedBarPainter(),
    );
  }
}

class _MandingStackedBarPainter extends CustomPainter {
  static const List<String> dates = [
    '12-Jun-19', '14-Jun-19', '16-Jun-19', '18-Jun-19', '20-Jun-19',
    '22-Jun-19', '24-Jun-19', '26-Jun-19', '28-Jun-19', '30-Jun-19',
    '2-Jul-19', '4-Jul-19', '6-Jul-19', '8-Jul-19', '10-Jul-19',
    '12-Jul-19', '14-Jul-19', '16-Jul-19', '18-Jul-19', '20-Jul-19',
    '22-Jul-19', '24-Jul-19', '26-Jul-19', '28-Jul-19', '30-Jul-19',
  ];

  static const List<double> prompted = [
    12, 14, 15, 0, 18, 17, 34, 42, 0, 38,
    20, 24, 26, 27, 0, 30, 48, 21, 52, 35,
    0, 0, 22, 38, 34,
  ];

  static const List<double> unprompted = [
    2, 2, 2, 0, 0, 1, 4, 3, 0, 2,
    13, 8, 32, 18, 0, 14, 8, 18, 11, 1,
    0, 0, 10, 24, 18,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 40.0;
    const rightPad = 20.0;
    const topPad = 15.0;
    const bottomPad = 65.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;
    final zeroY = size.height - bottomPad;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 0.8;

    final promptedPaint = Paint()..color = const Color(0xFF4A89DC);
    final unpromptedPaint = Paint()..color = const Color(0xFFC24138);

    // Draw horizontal gridlines & Y-axis labels: 0, 10, 20, 30, 40, 50, 60, 70
    for (int yVal = 0; yVal <= 70; yVal += 10) {
      final y = zeroY - (yVal / 70.0) * chartHeight;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '$yVal',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 8, y - tp.height / 2));
    }

    final stepX = chartWidth / dates.length;
    final barWidth = (stepX * 0.52).clamp(6.0, 14.0);

    for (int i = 0; i < dates.length; i++) {
      final x = leftPad + (i + 0.5) * stepX;
      final p = prompted[i];
      final u = unprompted[i];

      if (p > 0 || u > 0) {
        final pHeight = (p / 70.0) * chartHeight;
        final uHeight = (u / 70.0) * chartHeight;

        // Bottom stack (Prompted - Blue)
        if (p > 0) {
          final pRect = Rect.fromLTWH(x - barWidth / 2, zeroY - pHeight, barWidth, pHeight);
          canvas.drawRect(pRect, promptedPaint);
        }

        // Top stack (Unprompted - Red)
        if (u > 0) {
          final uRect = Rect.fromLTWH(x - barWidth / 2, zeroY - pHeight - uHeight, barWidth, uHeight);
          canvas.drawRect(uRect, unpromptedPaint);
        }
      }

      // X-axis rotated date label
      final dateTp = TextPainter(
        text: TextSpan(
          text: dates[i],
          style: const TextStyle(color: Color(0xFF4B5563), fontSize: 9.5, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(x, zeroY + 6);
      canvas.rotate(-math.pi / 4);
      dateTp.paint(canvas, Offset(-dateTp.width + 10, 0));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Manding Line Chart Widget (matches Figma Line Graph mode)
// ---------------------------------------------------------------------------
class _MandingLineChart extends StatelessWidget {
  const _MandingLineChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _MandingLinePainter(),
    );
  }
}

class _MandingLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 40.0;
    const rightPad = 20.0;
    const topPad = 15.0;
    const bottomPad = 65.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;
    final zeroY = size.height - bottomPad;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 0.8;

    final promptedLinePaint = Paint()
      ..color = const Color(0xFF4A89DC)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final promptedDotPaint = Paint()
      ..color = const Color(0xFF4A89DC)
      ..style = PaintingStyle.fill;

    final unpromptedLinePaint = Paint()
      ..color = const Color(0xFFC24138)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final unpromptedDotPaint = Paint()
      ..color = const Color(0xFFC24138)
      ..style = PaintingStyle.fill;

    // Y-axis gridlines & labels
    for (int yVal = 0; yVal <= 70; yVal += 10) {
      final y = zeroY - (yVal / 70.0) * chartHeight;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '$yVal',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 8, y - tp.height / 2));
    }

    final dates = _MandingStackedBarPainter.dates;
    final prompted = _MandingStackedBarPainter.prompted;
    final unprompted = _MandingStackedBarPainter.unprompted;
    final stepX = chartWidth / dates.length;

    final pPath = Path();
    final uPath = Path();
    bool pStarted = false;
    bool uStarted = false;

    for (int i = 0; i < dates.length; i++) {
      final x = leftPad + (i + 0.5) * stepX;
      final p = prompted[i];
      final u = unprompted[i];

      final pY = zeroY - (p / 70.0) * chartHeight;
      final uY = zeroY - (u / 70.0) * chartHeight;

      if (!pStarted) {
        pPath.moveTo(x, pY);
        pStarted = true;
      } else {
        pPath.lineTo(x, pY);
      }

      if (!uStarted) {
        uPath.moveTo(x, uY);
        uStarted = true;
      } else {
        uPath.lineTo(x, uY);
      }

      // X-axis rotated date label
      final dateTp = TextPainter(
        text: TextSpan(
          text: dates[i],
          style: const TextStyle(color: Color(0xFF4B5563), fontSize: 9.5, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(x, zeroY + 6);
      canvas.rotate(-math.pi / 4);
      dateTp.paint(canvas, Offset(-dateTp.width + 10, 0));
      canvas.restore();
    }

    canvas.drawPath(pPath, promptedLinePaint);
    canvas.drawPath(uPath, unpromptedLinePaint);

    // Draw dots
    for (int i = 0; i < dates.length; i++) {
      final x = leftPad + (i + 0.5) * stepX;
      final p = prompted[i];
      final u = unprompted[i];

      canvas.drawCircle(Offset(x, zeroY - (p / 70.0) * chartHeight), 3.5, promptedDotPaint);
      canvas.drawCircle(Offset(x, zeroY - (u / 70.0) * chartHeight), 3.5, unpromptedDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Acquisition Line Chart Widget (matches Figma THERAPIST DALIY DATA SHEET #729:4045)
// ---------------------------------------------------------------------------
class _AcquisitionLineChart extends StatelessWidget {
  const _AcquisitionLineChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _AcquisitionLinePainter(),
    );
  }
}

class _AcquisitionLinePainter extends CustomPainter {
  static const List<double> cumulative = [
    2, 4, 6, 8, 9, 11, 13, 15, 16, 18, 19, 21, 23, 24, 24, 25, 25, 26, 26, 26, 26, 26, 26, 26, 26,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 40.0;
    const rightPad = 20.0;
    const topPad = 15.0;
    const bottomPad = 65.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;
    final zeroY = size.height - bottomPad;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 0.8;

    // Y-axis gridlines & labels: 0, 5, 10, 15, 20, 25, 30
    for (int yVal = 0; yVal <= 30; yVal += 5) {
      final y = zeroY - (yVal / 30.0) * chartHeight;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '$yVal',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 8, y - tp.height / 2));
    }

    // Horizontal criteria threshold line at 26
    final thresholdY = zeroY - (26.0 / 30.0) * chartHeight;
    final thresholdPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // Draw dashed threshold line
    double startX = leftPad;
    while (startX < size.width - rightPad) {
      canvas.drawLine(Offset(startX, thresholdY), Offset(math.min(startX + 8, size.width - rightPad), thresholdY), thresholdPaint);
      startX += 14;
    }

    final dates = _MandingStackedBarPainter.dates;
    final stepX = chartWidth / dates.length;

    final linePath = Path();
    final fillPath = Path();

    for (int i = 0; i < dates.length; i++) {
      final x = leftPad + (i + 0.5) * stepX;
      final val = cumulative[i];
      final y = zeroY - (val / 30.0) * chartHeight;

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, zeroY);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // X-axis rotated date label
      final dateTp = TextPainter(
        text: TextSpan(
          text: dates[i],
          style: const TextStyle(color: Color(0xFF4B5563), fontSize: 9.5, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(x, zeroY + 6);
      canvas.rotate(-math.pi / 4);
      dateTp.paint(canvas, Offset(-dateTp.width + 10, 0));
      canvas.restore();
    }

    // Complete fill path
    final lastX = leftPad + (dates.length - 0.5) * stepX;
    fillPath.lineTo(lastX, zeroY);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.3),
          AppColors.primary.withValues(alpha: 0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(leftPad, topPad, chartWidth, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final dotWhitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < dates.length; i++) {
      final x = leftPad + (i + 0.5) * stepX;
      final val = cumulative[i];
      final y = zeroY - (val / 30.0) * chartHeight;

      canvas.drawCircle(Offset(x, y), 4.5, dotPaint);
      canvas.drawCircle(Offset(x, y), 2.5, dotWhitePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
