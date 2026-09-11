import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'admin_therapist_add_dialog.dart';
import '../accounts/admin_initiate_reset_dialog.dart';

class AdminTherapistsPage extends StatefulWidget {
  const AdminTherapistsPage({super.key});

  @override
  State<AdminTherapistsPage> createState() => _AdminTherapistsPageState();
}

class _AdminTherapistsPageState extends State<AdminTherapistsPage> {
  List<Map<String, dynamic>> _therapists = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTherapists();
  }

  Future<void> _loadTherapists() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiService().get('get_therapists');
      if (res is List) {
        setState(() {
          _therapists = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      } else if (res is Map && res['error'] != null) {
        setState(() {
          _error = res['error'].toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _therapists = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Our Therapists', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => const AdminTherapistAddDialog(),
                  );
                  _loadTherapists();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.statusDeactivated, size: 40),
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadTherapists, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _therapists.isEmpty
                        ? const Center(
                            child: Text('No therapists registered in database.', style: TextStyle(color: AppColors.textSecondary)),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = 4;
                              if (constraints.maxWidth < 500) {
                                crossAxisCount = 1;
                              } else if (constraints.maxWidth < 800) {
                                crossAxisCount = 2;
                              } else if (constraints.maxWidth < 1100) {
                                crossAxisCount = 3;
                              }

                              return GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: constraints.maxWidth < 500 ? 1.3 : 0.88,
                                ),
                                itemCount: _therapists.length,
                                itemBuilder: (context, index) {
                                  final therapist = _therapists[index];
                                  final name = therapist['name'] ?? 'Therapist';
                                  final email = therapist['email'] ?? '';
                                  final designation = therapist['designation'] ?? 'Behavior Therapist';
                                  final userId = therapist['id'] is int ? therapist['id'] : int.tryParse(therapist['id'].toString()) ?? 0;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.border),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x0A000000),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary, size: 20),
                                            tooltip: 'Therapist Options',
                                            onSelected: (val) {
                                              if (val == 'reset') {
                                                AdminInitiateResetDialog.show(
                                                  context: context,
                                                  userId: userId,
                                                  userName: name,
                                                  userEmail: email,
                                                  userRole: 'therapist',
                                                );
                                              }
                                            },
                                            itemBuilder: (ctx) => [
                                              const PopupMenuItem(
                                                value: 'reset',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.lock_reset, size: 18, color: AppColors.primary),
                                                    SizedBox(width: 8),
                                                    Text('Request Password Reset'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              AppImages.therapistImage(
                                                width: 80,
                                                height: 80,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              const SizedBox(height: 14),
                                              Text(
                                                name,
                                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                designation,
                                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
