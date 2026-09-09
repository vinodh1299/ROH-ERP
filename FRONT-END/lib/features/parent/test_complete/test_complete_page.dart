// lib/features/parent/test_complete/test_complete_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ParentTestCompletePage extends StatefulWidget {
  const ParentTestCompletePage({super.key});

  @override
  State<ParentTestCompletePage> createState() => _ParentTestCompletePageState();
}

class _ParentTestCompletePageState extends State<ParentTestCompletePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          // Top Navigation Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.check_circle_outline), text: 'VB-MAPP Complete'),
                Tab(icon: Icon(Icons.warning_amber_outlined), text: 'Barriers Complete'),
                Tab(icon: Icon(Icons.school_outlined), text: 'Transition Complete'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVbMappCompleteFrame(context),
                _buildBarriersCompleteFrame(context),
                _buildTransitionCompleteFrame(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Frame 1: VB-MAPP Test Complete ──────────────────────────────────────────
  Widget _buildVbMappCompleteFrame(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Celebration Top Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF673AB7), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.verified, color: Colors.green, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'VB-MAPP ASSESSMENT COMPLETE! 🎉',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Noah Johnson\'s official VB-MAPP milestone evaluation results are now available.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Downloading official VB-MAPP PDF Report...')),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF673AB7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Cards Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score Summary Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Score Breakdown Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text('Total Score: 145 / 170', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildLevelGauge('Level 1', '100%', Colors.green),
                          _buildLevelGauge('Level 2', '85%', Colors.orange),
                          _buildLevelGauge('Level 3', '70%', Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Therapist Notes Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Therapist Notes & Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Text(
                        'Noah has shown significant progress in verbal requests (Manding) and following listener instructions. Social interactions are improving but need continued focus. Excellent effort throughout the assessment!',
                        style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                      ),
                      SizedBox(height: 16),
                      Text('Assessed By: Sarah Adams (BCBA)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Frame 2: Barriers Assessment Complete ───────────────────────────────────
  Widget _buildBarriersCompleteFrame(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Color(0xFFE65100), size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'BARRIERS ASSESSMENT COMPLETE',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Learning barrier identification results are now finalized.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Severity Score Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Overall Severity Index', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Text('Barrier Level: ', style: TextStyle(fontSize: 14)),
                          Text('Low Severity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('12 / 96', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFE65100))),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: 12 / 96, backgroundColor: Colors.grey.shade200, color: Colors.green, minHeight: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Key Identified Barriers
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Key Identified Barriers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildBarrierRow('1. Prompt Dependency', '2 / 4 (Moderate)', Colors.orange),
                      const Divider(height: 16),
                      _buildBarrierRow('2. Hyperactivity', '1 / 4 (Low)', Colors.green),
                      const Divider(height: 16),
                      _buildBarrierRow('3. Instructional Control', '1 / 4 (Low)', Colors.green),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Frame 3: Transition Assessment Complete ──────────────────────────────────
  Widget _buildTransitionCompleteFrame(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0288D1), Color(0xFF039BE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.school, color: Color(0xFF0288D1), size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'TRANSITION READINESS COMPLETE',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'School transition readiness assessment complete.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Readiness Gauge Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Text('Overall Readiness Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('82%', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF0288D1))),
                const Text('Ready for School Mainstream Transition', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildReadinessBar('Academic Readiness', 0.85),
                    const SizedBox(width: 16),
                    _buildReadinessBar('Social Group Readiness', 0.75),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildReadinessBar('Self-Help Skills', 0.90),
                    const SizedBox(width: 16),
                    _buildReadinessBar('Classroom Behaviors', 0.80),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelGauge(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Center(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color))),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildBarrierRow(String name, String level, Color color) {
    return Row(
      children: [
        Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Text(level, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }

  Widget _buildReadinessBar(String title, double factor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${(factor * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0288D1))),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: factor, backgroundColor: Colors.grey.shade200, color: const Color(0xFF0288D1), minHeight: 6),
        ],
      ),
    );
  }
}
