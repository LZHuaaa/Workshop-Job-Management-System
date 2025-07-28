import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/schedule_overview_card.dart';
import '../widgets/management_hub_card.dart';
import '../widgets/inventory_card.dart';
import '../widgets/pending_approvals_card.dart';
import '../theme/app_colors.dart';
import 'user_profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, Sarah',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Workshop Manager',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.notifications_outlined,
                              color: AppColors.textDark,
                              size: 24,
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.primaryPink,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(
                                userName: 'Sarah Manager',
                                email: 'sarah.manager@example.com',
                                contactNumber: '123-456-7890',
                                password: 'password123',
                                onLogout: () {
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                  // TODO: Add actual logout logic
                                },
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primaryPink.withOpacity(0.1),
                          child: Text(
                            'SM',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryPink,
                            ),
                          ),
                        ),
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
                    ),
                    const SizedBox(height: 20),
                    const ManagementHubCard(),
                    const SizedBox(height: 20),
                    InventoryCard(
                      onOrdersCreated: (orders) {
                        // Handle procurement orders
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${orders.length} procurement order${orders.length != 1 ? 's' : ''} created',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const PendingApprovalsCard(),
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
