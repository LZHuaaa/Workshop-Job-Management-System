import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'schedule_screen.dart';
import 'jobs_screen.dart';
import 'invoice_management_screen.dart';

class WorkScreen extends StatefulWidget {
  const WorkScreen({super.key});

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  int _selectedView = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Work Management',
          style: TextStyle(color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 32,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTabButton(0, 'Calendar', Icons.calendar_today),
                    _buildTabButton(1, 'Jobs', Icons.build),
                    _buildTabButton(2, 'Invoices', Icons.receipt),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedView,
        children: const [
          ScheduleScreen(),
          JobsScreen(),
          InvoiceManagementScreen(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedView == index;
    return InkWell(
      onTap: () => setState(() => _selectedView = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPink : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_selectedView) {
      case 0: // Calendar
        return FloatingActionButton(
          onPressed: () {
            // Show add appointment dialog
          },
          backgroundColor: AppColors.primaryPink,
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 1: // Jobs
        return FloatingActionButton(
          onPressed: () {
            // Show add job dialog
          },
          backgroundColor: AppColors.primaryPink,
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 2: // Invoices
        return FloatingActionButton(
          onPressed: () {
            // Show create invoice dialog
          },
          backgroundColor: AppColors.primaryPink,
          child: const Icon(Icons.add, color: Colors.white),
        );
      default:
        return null;
    }
  }
} 