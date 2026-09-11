import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'admin_add_guardian_dialog.dart';

class AdminStudentFormPage extends StatefulWidget {
  final VoidCallback onBack;
  const AdminStudentFormPage({super.key, required this.onBack});

  @override
  State<AdminStudentFormPage> createState() => _AdminStudentFormPageState();
}

class _AdminStudentFormPageState extends State<AdminStudentFormPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
              const Text('Add Student', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.white,
                    indicator: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    tabs: const [
                      Tab(text: 'STUDENTS INFORMATION'),
                      Tab(text: 'MEDICATION HISTORY'),
                      Tab(text: 'EMERGENCY CONTACT INFO'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTab1(),
                      _buildTab2(),
                      _buildTab3(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTab1() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        Widget wrapRow(List<Widget> children) {
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList(),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: c))).toList(),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              wrapRow([
                _buildTextField('Last Name'),
                _buildTextField('First Name'),
                _buildTextField('Middle Name'),
              ]),
              wrapRow([
                _buildTextField('Phone Number'),
                _buildTextField('Email Id'),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gender', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: const [DropdownMenuItem(value: 'Male', child: Text('Male'))],
                      onChanged: (v) {},
                      initialValue: 'Male',
                    ),
                  ],
                ),
              ]),
              wrapRow([
                _buildTextField('Date Of Birth'),
                _buildTextField('City Name'),
                _buildTextField('Pin Code'),
              ]),
              _buildTextField('Address', maxLines: 3),
              const SizedBox(height: 16),
              wrapRow([
                _buildTextField('Blood Group'),
                _buildTextField('Date of Application'),
                if (!isNarrow) const SizedBox(),
              ]),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => _tabController.animateTo(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Next'),
              ),
            ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 650,
              child: Table(
                border: TableBorder.all(color: AppColors.divider),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(2),
                  5: FixedColumnWidth(50),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: Colors.white),
                    children: [
                      Padding(padding: EdgeInsets.all(8.0), child: Text('Medication', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(8.0), child: Text('Date Prescribed', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(8.0), child: Text('Dosage', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(8.0), child: Text('Administration Timelines', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(8.0), child: Text('Used For', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(8.0), child: Text('')),
                    ],
                  ),
                  ...List.generate(3, (index) => TableRow(
                    decoration: const BoxDecoration(color: Colors.white),
                    children: [
                      const Padding(padding: EdgeInsets.all(8.0), child: TextField(decoration: InputDecoration(border: InputBorder.none))),
                      const Padding(padding: EdgeInsets.all(8.0), child: TextField(decoration: InputDecoration(border: InputBorder.none))),
                      const Padding(padding: EdgeInsets.all(8.0), child: TextField(decoration: InputDecoration(border: InputBorder.none))),
                      const Padding(padding: EdgeInsets.all(8.0), child: TextField(decoration: InputDecoration(border: InputBorder.none))),
                      const Padding(padding: EdgeInsets.all(8.0), child: TextField(decoration: InputDecoration(border: InputBorder.none))),
                      Padding(padding: const EdgeInsets.all(8.0), child: IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () {})),
                    ],
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('+ Add')),
          const SizedBox(height: 24),
          _buildQuestion('1. Has your child ever been admitted to a hospital/treatment center...'),
          _buildQuestion('2. Has your child been diagnosed with any medical conditions...'),
          _buildQuestion('3. Has your child been diagnosed with infectious diseases?'),
          _buildQuestion('4. Does your child have food or other types of allergies...'),
          _buildQuestion('5. Describe your child eating habits:'),
          _buildQuestion('6. Describe your child sleeping habits:'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _tabController.animateTo(0),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Previous'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => _tabController.animateTo(2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(String q) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q, style: const TextStyle(color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            maxLines: 2,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab3() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(context: context, builder: (context) => const AdminAddGuardianDialog());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Guardian'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  )
                ],
              ),
              const SizedBox(height: 16),
              if (isNarrow) ...[
                _buildGuardianCard('GUARDIAN #1'),
                const SizedBox(height: 16),
                _buildGuardianCard('GUARDIAN #2'),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _buildGuardianCard('GUARDIAN #1')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildGuardianCard('GUARDIAN #2')),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                child: const Text('Emergency Contact Information', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 16),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('+ Add')),
              const SizedBox(height: 16),
              if (isNarrow) ...[
                _buildTextField('Name'),
                const SizedBox(height: 16),
                _buildTextField('Name'),
                const SizedBox(height: 16),
                _buildTextField('Name'),
                const SizedBox(height: 16),
                _buildTextField('Name'),
                const SizedBox(height: 16),
                _buildTextField('Name'),
                const SizedBox(height: 16),
                _buildTextField('Message', maxLines: 3),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _buildTextField('Name')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Name')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Name')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Name')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Name')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Message', maxLines: 3)),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _tabController.animateTo(1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Previous'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuardianCard(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          _buildInfoRow('Name', 'xxxxxxxxxxx'),
          _buildInfoRow('Relationship', 'xxxxxxxxxxx'),
          _buildInfoRow('Street Address', 'xxxxxxxxxxx'),
          _buildInfoRow('City', 'xxxxxxxxxxx'),
          _buildInfoRow('State', 'xxxxxxxxxxx'),
          _buildInfoRow('Phone', 'xxxxxxxxxxx'),
          _buildInfoRow('Email Id', 'xxxxxxxxxxx'),
          _buildInfoRow('Number of adults', 'xxxxxxxxxxx'),
          _buildInfoRow('Number of children', 'xxxxxxxxxxx'),
          _buildInfoRow('Name of adults', 'xxxxxxxxxxx'),
          _buildInfoRow('Name of childrens', 'xxxxxxxxxxx'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
