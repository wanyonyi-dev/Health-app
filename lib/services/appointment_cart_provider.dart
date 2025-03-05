import 'package:flutter/foundation.dart';

import '../appointment_booking_screen.dart';
import '../appointment_cart_provider.dart';

class AppointmentCartProvider extends ChangeNotifier {
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