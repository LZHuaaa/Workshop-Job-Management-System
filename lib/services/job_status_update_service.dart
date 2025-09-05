import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_appointment.dart';

class JobStatusUpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks and updates status of jobs that are overdue
  Future<void> updateOverdueJobs() async {
    try {
      // Get current time
      final DateTime now = DateTime.now();
      // Get yesterday's date to check for overdue jobs
      final DateTime yesterday = DateTime(now.year, now.month, now.day - 1);

      // Query for jobs that are:
      // 1. End time is before today (overdue)
      // 2. Status is still either scheduled or in progress
      final QuerySnapshot snapshot = await _firestore
          .collection('appointments')
          .where('endTime', isLessThan: Timestamp.fromDate(yesterday))
          .where('status', whereIn: [JobStatus.scheduled.name, JobStatus.inProgress.name])
          .get();

      // Update each overdue job
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': 'overdue',
          'lastUpdated': Timestamp.now(),
        });
      }

      await batch.commit();

      print('Updated ${snapshot.docs.length} overdue jobs');
    } catch (e) {
      print('Error updating overdue jobs: $e');
    }
  }

  /// Sets up a periodic check for overdue jobs
  Stream<void> startPeriodicCheck() async* {
    while (true) {
      await updateOverdueJobs();
      // Wait for 15 minutes before checking again
      await Future.delayed(const Duration(minutes: 15));
      yield null;
    }
  }
}
