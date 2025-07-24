import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'dashboard_card.dart';

class PendingApprovalsCard extends StatefulWidget {
  const PendingApprovalsCard({super.key});

  @override
  State<PendingApprovalsCard> createState() => _PendingApprovalsCardState();
}

class _PendingApprovalsCardState extends State<PendingApprovalsCard> {
  final List<PendingApproval> _approvals = [
    PendingApproval(
      id: '1',
      type: ApprovalType.invoice,
      title: 'Invoice #INV-0078 for John Doe',
      subtitle: 'Brake pad replacement - \$245.00',
      status: ApprovalStatus.pending,
    ),
    PendingApproval(
      id: '2',
      type: ApprovalType.procurement,
      title: 'Procurement Request #P-045',
      subtitle: 'Engine oil filters - 50 units',
      status: ApprovalStatus.pending,
    ),
    PendingApproval(
      id: '3',
      type: ApprovalType.schedule,
      title: 'Schedule Change Request',
      subtitle: 'Move Honda Civic service to 3:00 PM',
      status: ApprovalStatus.pending,
    ),
  ];

  void _handleApproval(String id, bool approved) {
    setState(() {
      final index = _approvals.indexWhere((approval) => approval.id == id);
      if (index != -1) {
        _approvals[index] = _approvals[index].copyWith(
          status: approved ? ApprovalStatus.approved : ApprovalStatus.declined,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approved ? 'Request approved successfully!' : 'Request declined.',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor:
            approved ? AppColors.successGreen : AppColors.warningOrange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Action Required',
      child: Column(
        children: _approvals
            .where((approval) => approval.status == ApprovalStatus.pending)
            .map((approval) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildApprovalItem(
                    icon: _getIconForType(approval.type),
                    title: approval.title,
                    subtitle: approval.subtitle,
                    type: approval.type,
                    onApprove: approval.type == ApprovalType.procurement
                        ? null
                        : () => _handleApproval(approval.id, true),
                    onDecline: approval.type == ApprovalType.procurement
                        ? null
                        : () => _handleApproval(approval.id, false),
                    onTap: approval.type == ApprovalType.procurement
                        ? () => _handleApproval(approval.id, true)
                        : null,
                  ),
                ))
            .toList(),
      ),
    );
  }

  IconData _getIconForType(ApprovalType type) {
    switch (type) {
      case ApprovalType.invoice:
        return Icons.receipt_long;
      case ApprovalType.procurement:
        return Icons.shopping_cart;
      case ApprovalType.schedule:
        return Icons.schedule;
    }
  }

  Widget _buildApprovalItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required ApprovalType type,
    VoidCallback? onTap,
    VoidCallback? onApprove,
    VoidCallback? onDecline,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.softPink,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.lightPink.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryPink,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
              ],
            ),

            // Action Buttons for Invoice and Schedule types
            if (type == ApprovalType.invoice ||
                type == ApprovalType.schedule) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onDecline,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textSecondary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(
                            color: AppColors.textSecondary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        'Decline',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Approve',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum ApprovalType {
  invoice,
  procurement,
  schedule,
}

enum ApprovalStatus {
  pending,
  approved,
  declined,
}

class PendingApproval {
  final String id;
  final ApprovalType type;
  final String title;
  final String subtitle;
  final ApprovalStatus status;

  PendingApproval({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  PendingApproval copyWith({
    String? id,
    ApprovalType? type,
    String? title,
    String? subtitle,
    ApprovalStatus? status,
  }) {
    return PendingApproval(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      status: status ?? this.status,
    );
  }
}
