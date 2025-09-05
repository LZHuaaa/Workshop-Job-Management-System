import 'package:flutter/material.dart';
import '../services/job_status_update_service.dart';

class AppInitializer {
  static final JobStatusUpdateService _jobStatusService = JobStatusUpdateService();
  static bool _initialized = false;

  static void initializeApp(BuildContext context) {
    if (_initialized) return;
    _initialized = true;

    // Start periodic job status checks
    _jobStatusService.startPeriodicCheck().listen(
      (_) {},
      onError: (error) {
        print('Error in periodic job status check: $error');
      },
    );

    // Run an immediate check for overdue jobs
    _jobStatusService.updateOverdueJobs();
  }
}
