import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../appointment_booking_screen.dart';

class AppointmentCartProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;

  List<Appointment> get appointments => List.unmodifiable(_appointments);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize stream subscription
  void initializeAppointments(String userId) {
    _listenToAppointments(userId);
  }

  void _listenToAppointments(String userId) {
    _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _appointments = snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc.data()))
            .toList();
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> addAppointment(Appointment appointment) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .set(appointment.toMap());

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeAppointment(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('appointments').doc(id).delete();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearCart(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final batch = _firestore.batch();
      final snapshots = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

class Appointment {
  final String id;
  final String userId;
  final String patientName;
  final String phoneNumber;
  final int age;
  final String county;
  final String idNumber;
  final String serviceId;
  final String doctorId;
  final DateTime dateTime;
  final String session;
  final String status;

  Appointment({
    required this.id,
    required this.userId,
    required this.patientName,
    required this.phoneNumber,
    required this.age,
    required this.county,
    required this.idNumber,
    required this.serviceId,
    required this.doctorId,
    required this.dateTime,
    required this.session,
    this.status = 'pending',
  });

  factory Appointment.fromFirestore(Map<String, dynamic> data) {
    return Appointment(
      id: data['id'],
      userId: data['userId'],
      patientName: data['patientName'],
      phoneNumber: data['phoneNumber'],
      age: data['age'],
      county: data['county'],
      idNumber: data['idNumber'],
      serviceId: data['serviceId'],
      doctorId: data['doctorId'],
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      session: data['session'],
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'patientName': patientName,
      'phoneNumber': phoneNumber,
      'age': age,
      'county': county,
      'idNumber': idNumber,
      'serviceId': serviceId,
      'doctorId': doctorId,
      'dateTime': Timestamp.fromDate(dateTime),
      'session': session,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

// Cart UI Widget
class AppointmentCartScreen extends StatelessWidget {
  final AppointmentCartProvider cartProvider;
  final String userId;

  const AppointmentCartScreen({
    Key? key,
    required this.cartProvider,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Cart'),
        actions: [
          if (cartProvider.appointments.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _confirmClearCart(context),
            ),
        ],
      ),
      body: cartProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartProvider.appointments.isEmpty
              ? const Center(
                  child: Text('No appointments in cart'),
                )
              : ListView.builder(
                  itemCount: cartProvider.appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = cartProvider.appointments[index];
                    return AppointmentCard(
                      appointment: appointment,
                      onDelete: () => _confirmDelete(context, appointment.id),
                    );
                  },
                ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to remove this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cartProvider.removeAppointment(appointmentId);
    }
  }

  Future<void> _confirmClearCart(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all appointments from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cartProvider.clearCart(userId);
    }
  }
}

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onDelete;

  const AppointmentCard({
    Key? key,
    required this.appointment,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(appointment.patientName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${DateFormat('MMM d, y').format(appointment.dateTime)}',
            ),
            Text('Session: ${appointment.session}'),
            Text(
              'Status: ${appointment.status}',
              style: TextStyle(
                color: _getStatusColor(appointment.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}