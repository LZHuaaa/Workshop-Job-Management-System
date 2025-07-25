import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../screens/work_analytics_screen.dart';
import 'dashboard_card.dart';

class ManagementHubCard extends StatelessWidget {
  const ManagementHubCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Management Hub',
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.3,
        children: [
          _buildHubItem(
            icon: Icons.directions_car,
            title: 'Vehicle Details',
            subtitle: 'Manage customer vehicles',
            onTap: () {},
          ),
          _buildHubItem(
            icon: Icons.people,
            title: 'CRM',
            subtitle: 'Customer management',
            onTap: () {},
          ),
          _buildHubItem(
            icon: Icons.analytics,
            title: 'Work Analytics',
            subtitle: 'Performance insights',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkAnalyticsScreen(),
                ),
              );
            },
          ),
          _buildHubItem(
            icon: Icons.view_list,
            title: 'Full Schedule',
            subtitle: 'Detailed scheduler view',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHubItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPink.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: AppColors.lightPink.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with gradient background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPink.withOpacity(0.1),
                      AppColors.accentPink.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryPink.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryPink,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),

              // Title
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),

              // Subtitle
              Flexible(
                child: Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
