import 'package:flutter/material.dart';
import 'schedule_screen.dart';
import 'jobs_screen.dart';
import '../theme/app_colors.dart';

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SegmentedButton<int>(
              selected: {_selectedView},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _selectedView = newSelection.first;
                });
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return AppColors.primaryPink;
                    }
                    return Colors.transparent;
                  },
                ),
                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.white;
                    }
                    return AppColors.textDark;
                  },
                ),
              ),
              segments: const [
                ButtonSegment<int>(
                  value: 0,
                  label: Text('Calendar'),
                  icon: Icon(Icons.calendar_today),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text('Jobs'),
                  icon: Icon(Icons.build),
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedView,
        children: const [
          ScheduleScreen(),
          JobsScreen(),
        ],
      ),
    );
  }
} 