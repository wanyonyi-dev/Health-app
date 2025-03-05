import 'package:flutter/foundation.dart';

class Appointment {
  final String id;
  final String doctorName;
  final DateTime dateTime;

  Appointment({
    required this.id,
    required this.doctorName,
    required this.dateTime,
  });
}

class AppointmentCartProvider with ChangeNotifier {
  final List<Appointment> _appointments = [];
  List<Appointment> get appointments => List.unmodifiable(_appointments);

  void addAppointment(Appointment appointment) {
    if (!_appointments.any((a) => a.id == appointment.id)) {
      _appointments.add(appointment);
      notifyListeners();
    }
  }

  void removeAppointment(String id) {
    _appointments.removeWhere((appointment) => appointment.id == id);
    notifyListeners();
  }

  void clearCart() {
    _appointments.clear();
    notifyListeners();
  }
}