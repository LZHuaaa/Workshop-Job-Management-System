import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/job_appointment.dart';
import 'job_details_screen.dart';


class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<JobAppointment> _allAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  void _loadAppointments() {
    _firestore.collection('appointments')
        .orderBy('startTime', descending: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _allAppointments = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;

            // Handle Firestore Timestamp conversion
            if (data['startTime'] is Timestamp) {
              data['startTime'] = (data['startTime'] as Timestamp).toDate();
            }
            if (data['endTime'] is Timestamp) {
              data['endTime'] = (data['endTime'] as Timestamp).toDate();
            }

            return JobAppointment.fromMap(data);
          }).toList();
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<JobAppointment> _getAppointmentsForDay(DateTime day) {
    return _allAppointments.where((appointment) {
      return isSameDay(appointment.startTime, day);
    }).toList();
  }

  void _navigateToJobDetails(JobAppointment appointment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobDetailsScreen(
          job: appointment,
          onJobUpdated: (updatedJob) {
            // Update the appointment in the local list
            setState(() {
              final index = _allAppointments.indexWhere((job) => job.id == updatedJob.id);
              if (index != -1) {
                _allAppointments[index] = updatedJob;
              }
            });
          },
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryPink,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                        'Schedule',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(_selectedDay),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryPink,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primaryPink,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                tabs: const [
                  Tab(text: 'Month'),
                  Tab(text: 'Week'),
                  Tab(text: 'Day'),
                ],
              ),
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMonthView(),
                  _buildWeekView(),
                  _buildDayView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          DashboardCard(
            title: 'Calendar',
            child: TableCalendar<JobAppointment>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              eventLoader: _getAppointmentsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: BoxDecoration(
                  color: AppColors.primaryPink,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.accentPink,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: AppColors.primaryPink,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                ),
                defaultTextStyle: GoogleFonts.poppins(
                  color: AppColors.textDark,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: AppColors.primaryPink,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: AppColors.primaryPink,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
          const SizedBox(height: 20),
          if (_getAppointmentsForDay(_selectedDay).isNotEmpty)
            DashboardCard(
              title:
                  'Appointments for ${DateFormat('MMM d').format(_selectedDay)}',
              child: Column(
                children: _getAppointmentsForDay(_selectedDay)
                    .map((appointment) => _buildAppointmentCard(appointment))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekView() {
    final startOfWeek =
        _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));
    final weekDays =
        List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Week Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
              children: weekDays.map((day) {
                final isSelected = isSameDay(day, _selectedDay);
                final hasAppointments = _getAppointmentsForDay(day).isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = day;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryPink
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(day),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day.day.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected ? Colors.white : AppColors.textDark,
                          ),
                        ),
                        if (hasAppointments && !isSelected)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPink,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Selected Day Appointments
          if (_getAppointmentsForDay(_selectedDay).isNotEmpty)
            DashboardCard(
              title:
                  'Appointments for ${DateFormat('MMM d').format(_selectedDay)}',
              child: Column(
                children: _getAppointmentsForDay(_selectedDay)
                    .map((appointment) => _buildAppointmentCard(appointment))
                    .toList(),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No appointments scheduled',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'for ${DateFormat('EEEE, MMM d').format(_selectedDay)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayView() {
    final appointments = _getAppointmentsForDay(_selectedDay);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Day Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE').format(_selectedDay),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM d, y').format(_selectedDay),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${appointments.length} appointment${appointments.length != 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Time Slots
          if (appointments.isNotEmpty)
            ...appointments.map((appointment) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildDayAppointmentCard(appointment),
                ))
          else
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.free_breakfast,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Free day!',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'No appointments scheduled for today',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(JobAppointment appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToJobDetails(appointment),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(appointment.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(appointment.status).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appointment.vehicleInfo,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appointment.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        appointment.status.name.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${appointment.customerName} • ${appointment.mechanicName}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${DateFormat('h:mm a').format(appointment.startTime)} - ${DateFormat('h:mm a').format(appointment.endTime)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayAppointmentCard(JobAppointment appointment) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToJobDetails(appointment),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Time Column
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(appointment.startTime),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPink,
                      ),
                    ),
                    Text(
                      DateFormat('h:mm a').format(appointment.endTime),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                width: 2,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.status),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            appointment.vehicleInfo,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(appointment.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            appointment.status.name.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appointment.serviceType,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${appointment.customerName} • ${appointment.mechanicName}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.scheduled:
        return AppColors.accentPink;
      case JobStatus.inProgress:
        return AppColors.primaryPink;
      case JobStatus.completed:
        return AppColors.successGreen;
      case JobStatus.cancelled:
        return AppColors.textSecondary;
      case JobStatus.overdue:
        return AppColors.errorRed;
    }
  }


}
