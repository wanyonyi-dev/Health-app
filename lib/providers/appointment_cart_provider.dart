import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/appointment.dart';

class AppointmentCartProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Appointment> _appointments = [];
  StreamSubscription<QuerySnapshot>? _appointmentSubscription;
  bool _isLoading = false;
  String? _error;

  List<Appointment> get appointments => List.unmodifiable(_appointments);
  bool get isLoading => _isLoading;
  String? get error => _error;

  AppointmentCartProvider() {
    _initializeAppointmentListener();
  }

  void _initializeAppointmentListener() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _appointmentSubscription = _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _appointments = snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
      notifyListeners();
    });
  }

  Stream<List<Appointment>> getUpcomingAppointments(String userId) {
    final now = DateTime.now();
    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: userId)
        .where('dateTime', isGreaterThanOrEqualTo: now)
        .orderBy('dateTime')
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc))
            .toList());
  }

  Future<void> addAppointment(Appointment appointment) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final docRef = await _firestore.collection('appointments').add({
        'patientId': userId,
        ...appointment.toMap(),
      });

      // Update local state with the new appointment including its ID
      final newAppointment = Appointment.fromFirestore(
        await docRef.get().then((doc) => doc as DocumentSnapshot<Map<String, dynamic>>)
      );
      _appointments.add(await newAppointment);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeAppointment(String appointmentId) async {
    if (appointmentId.isEmpty) {
      _error = 'Invalid appointment ID';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final docRef = _firestore.collection('appointments').doc(appointmentId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Appointment not found',
        );
      }

      await docRef.update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': _auth.currentUser?.uid ?? 'unknown',
      });

      // Update local state
      _appointments.removeWhere((app) => app.id == appointmentId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    try {
      final batch = _firestore.batch();
      final snapshots = await _firestore.collection('appointments').get();
      
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing cart in Firestore: $e');
      rethrow;
    }
  }

  Future<List<Appointment>> fetchAppointments() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: userId)
          .get();

      _appointments = snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
      
      notifyListeners();
      return _appointments;
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  @override
  void dispose() {
    _appointmentSubscription?.cancel();
    super.dispose();
  }
}