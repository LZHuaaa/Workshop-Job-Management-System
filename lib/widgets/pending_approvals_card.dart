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
      submittedDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    PendingApproval(
      id: '2',
      type: ApprovalType.procurement,
      title: 'Procurement Request #P-045',
      subtitle: 'Engine oil filters - 50 units',
      status: ApprovalStatus.pending,
      submittedDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PendingApproval(
      id: '3',
      type: ApprovalType.schedule,
      title: 'Schedule Change Request',
      subtitle: 'Move Honda Civic service to 3:00 PM',
      status: ApprovalStatus.pending,
      submittedDate: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Pending Requests',
      subtitle: 'Waiting for company approval',
      child: Column(
        children: _approvals
            .where((approval) => approval.status == ApprovalStatus.pending)
            .map((approval) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPendingRequestItem(
                    icon: _getIconForType(approval.type),
                    title: approval.title,
                    subtitle: approval.subtitle,
                    type: approval.type,
                    submittedDate: approval.submittedDate,
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

  Widget _buildPendingRequestItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required ApprovalType type,
    required DateTime submittedDate,
  }) {
    return Container(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFA500)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pending,
                      size: 12,
                      color: const Color(0xFFFFA500),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pending',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFA500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Submitted ${_getTimeAgo(submittedDate)}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'Waiting for company review',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
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
  final DateTime submittedDate;

  PendingApproval({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.submittedDate,
  });

  PendingApproval copyWith({
    String? id,
    ApprovalType? type,
    String? title,
    String? subtitle,
    ApprovalStatus? status,
    DateTime? submittedDate,
  }) {
    return PendingApproval(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      status: status ?? this.status,
      submittedDate: submittedDate ?? this.submittedDate,
    );
  }
}
