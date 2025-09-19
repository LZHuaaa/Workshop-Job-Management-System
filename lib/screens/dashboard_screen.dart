import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/schedule_overview_card.dart';
import '../widgets/management_hub_card.dart';
import '../widgets/notification_badge.dart';
import '../widgets/notification_panel.dart';
import '../widgets/dynamic_greeting_widget.dart';
import '../widgets/user_avatar_widget.dart';
import '../services/notification_service_factory.dart';
import '../theme/app_colors.dart';
import 'user_profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onTabSwitch;
  
  const DashboardScreen({super.key, this.onTabSwitch});

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationPanel(
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const DynamicGreetingWidget(
                    subtitle: 'Workshop Manager',
                  ),
                  Row(
                    children: [
                      NotificationBadge(
                        onTap: () => _showNotificationPanel(context),
                      ),
                      const SizedBox(width: 8),
                      UserAvatarWidget(
                        radius: 20,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const UserProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Content - Scrollable Cards
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ScheduleOverviewCard(
                      onJobCreated: (job) {
                        // Handle job creation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Job created: ${job.vehicleInfo}',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      },
                      onTabSwitch: onTabSwitch,
                    ),
                    const SizedBox(height: 20),
                    ManagementHubCard(onTabSwitch: onTabSwitch),
                    const SizedBox(
                        height: 100), // Extra space for bottom navigation
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
