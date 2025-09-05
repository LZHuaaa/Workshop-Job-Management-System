import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_appointment.dart';

class JobAppointmentService {
  static final JobAppointmentService _instance =
      JobAppointmentService._internal();
  factory JobAppointmentService() => _instance;
  JobAppointmentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _appointmentsRef =>
      _firestore.collection('appointments');

  /// Get all appointments with real-time updates
  Stream<List<JobAppointment>> getAppointmentsStream() {
    return _appointmentsRef
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
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
    });
  }

  /// Get appointments for a specific date
  Future<List<JobAppointment>> getAppointmentsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final querySnapshot = await _appointmentsRef
        .where('startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('startTime')
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
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
  }

  /// Add a new appointment
  Future<String> addAppointment(JobAppointment appointment) async {
    try {
      final docRef = await _appointmentsRef.add({
        'vehicleInfo': appointment.vehicleInfo,
        'customerName': appointment.customerName,
        'mechanicName': appointment.mechanicName,
        'startTime': Timestamp.fromDate(appointment.startTime),
        'endTime': Timestamp.fromDate(appointment.endTime),
        'serviceType': appointment.serviceType,
        'status': appointment.status.name,
        'notes': appointment.notes,
        'partsNeeded': appointment.partsNeeded,
        'estimatedCost': appointment.estimatedCost,
      });

      // Update the document with its own ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw JobAppointmentServiceException(
          'Failed to add appointment: ${e.toString()}');
    }
  }

  /// Update an existing appointment
  Future<void> updateAppointment(JobAppointment appointment) async {
    try {
      await _appointmentsRef.doc(appointment.id).update({
        'vehicleInfo': appointment.vehicleInfo,
        'customerName': appointment.customerName,
        'mechanicName': appointment.mechanicName,
        'startTime': Timestamp.fromDate(appointment.startTime),
        'endTime': Timestamp.fromDate(appointment.endTime),
        'serviceType': appointment.serviceType,
        'status': appointment.status.name,
        'notes': appointment.notes,
        'partsNeeded': appointment.partsNeeded,
        'estimatedCost': appointment.estimatedCost,
      });
    } catch (e) {
      throw JobAppointmentServiceException(
          'Failed to update appointment: ${e.toString()}');
    }
  }

  /// Delete an appointment
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _appointmentsRef.doc(appointmentId).delete();
    } catch (e) {
      throw JobAppointmentServiceException(
          'Failed to delete appointment: ${e.toString()}');
    }
  }

  /// Get a single appointment by ID
  Future<JobAppointment?> getAppointment(String appointmentId) async {
    try {
      final doc = await _appointmentsRef.doc(appointmentId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      // Handle Firestore Timestamp conversion
      if (data['startTime'] is Timestamp) {
        data['startTime'] = (data['startTime'] as Timestamp).toDate();
      }
      if (data['endTime'] is Timestamp) {
        data['endTime'] = (data['endTime'] as Timestamp).toDate();
      }

      return JobAppointment.fromMap(data);
    } catch (e) {
      throw JobAppointmentServiceException(
          'Failed to get appointment: ${e.toString()}');
    }
  }
}

class JobAppointmentServiceException implements Exception {
  final String message;
  JobAppointmentServiceException(this.message);

  @override
  String toString() => 'JobAppointmentServiceException: $message';
}
