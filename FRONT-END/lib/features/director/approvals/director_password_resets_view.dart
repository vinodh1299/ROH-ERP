// lib/features/director/approvals/director_password_resets_view.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';

class DirectorPasswordResetsView extends StatefulWidget {
  const DirectorPasswordResetsView({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(24),
        child: DirectorPasswordResetsView(),
      ),
    );
  }

  @override
  State<DirectorPasswordResetsView> createState() => _DirectorPasswordResetsViewState();
}

class _DirectorPasswordResetsViewState extends State<DirectorPasswordResetsView> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('list_pending_password_resets');
      if (res is List) {
        setState(() {
          _requests = res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    // Mock fallback
    setState(() {
      _requests = [
        {
          'id': 1,
          'user_id': 3,
          'user_name': 'Dr. Sarah Lee',
          'user_email': 'therapist@roh.com',
          'user_role': 'therapist',
          'admin_name': 'System Admin',
          'decision': 'Pending',
          'request_timestamp': '2026-09-11 08:30:00',
          'expires_at': '2026-09-13 08:30:00',
          'requester_ip': '127.0.0.1',
          'rejection_reason': 'Therapist locked out of cabin device',
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _decide(int requestId, String decision) async {
    final reasonController = TextEditingController();
    if (decision == 'Rejected') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Reject Password Reset', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              hintText: 'Enter reason for rejection...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              child: const Text('Reject', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      final res = await _api.post('decide_password_reset', {
        'request_id': requestId,
        'decision': decision,
        'reason': reasonController.text,
      });

      if (res is Map<String, dynamic> && res['temporary_password'] != null) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Text('Reset Approved', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('A temporary password was generated. Deliver this securely to the user:'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: SelectableText(
                    '${res['temporary_password']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary, letterSpacing: 1),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('The user will be forced to change this password on their next login.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Done')),
            ],
          ),
        );
      }
    } catch (_) {}

    await _fetchRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 720,
      constraints: const BoxConstraints(maxHeight: 600),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Director Password Reset Approvals',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  Text(
                    'FRS 3.0 Governance • Zero plaintext passwords • 10-point audit log',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                    ? const Center(
                        child: Text('No pending password reset requests.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      )
                    : ListView.separated(
                        itemCount: _requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final req = _requests[index];
                          final isPending = req['decision'] == 'Pending';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${req['user_name']} (${req['user_role']?.toString().toUpperCase()})',
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                                          ),
                                          Text(
                                            'Email: ${req['user_email']} • Requested by: ${req['admin_name']}',
                                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${req['decision']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isPending ? const Color(0xFFB45309) : const Color(0xFF15803D),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Reason: ${req['rejection_reason'] ?? "N/A"}',
                                  style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Expires: ${req['expires_at']} (48h rule) • Requester IP: ${req['requester_ip']}',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                                ),
                                if (isPending) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => _decide(req['id'], 'Rejected'),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFFDC2626)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Reject', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600, fontSize: 13)),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () => _decide(req['id'], 'Approved'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF16A34A),
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Approve & Generate Temp Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
