import 'package:cloud_functions/cloud_functions.dart';
import '../models/appointment.dart';
import 'package:intl/intl.dart';

class EmailService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> sendAppointmentConfirmation({
    required Appointment appointment,
    required String patientEmail,
    required String serviceName,
    required String doctorName,
  }) async {
    try {
      await _functions.httpsCallable('sendAppointmentEmail').call({
        'to': patientEmail,
        'subject': 'Appointment Confirmation',
        'appointmentDetails': {
          'patientName': appointment.patientName,
          'date': DateFormat('MMMM dd, yyyy').format(appointment.dateTime),
          'time': DateFormat('hh:mm a').format(appointment.dateTime),
          'session': appointment.session,
          'doctor': doctorName,
          'service': serviceName,
          'location': 'Health Connect Clinic',
          'contactNumber': '+254XXXXXXXXX',
        },
      });
    } catch (e) {
      print('Error sending email: $e');
      rethrow;
    }
  }
} 