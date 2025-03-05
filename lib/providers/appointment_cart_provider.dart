import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/appointment.dart';

class AppointmentCartProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
    _appointmentSubscription = _firestore
        .collection('appointments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _appointments = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Appointment.fromMap(data);
      }).toList();
      notifyListeners();
    });
  }

  Stream<List<Appointment>> getUpcomingAppointments(String userId) {
    final now = DateTime.now();
    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .where('dateTime', isGreaterThanOrEqualTo: now)
        .orderBy('dateTime')
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addAppointment(Appointment appointment) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('appointments').doc(appointment.id).set({
        ...appointment.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error adding appointment to Firestore: $e');
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
      debugPrint('Error removing appointment from Firestore: $e');
      rethrow;
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

  @override
  void dispose() {
    _appointmentSubscription?.cancel();
    super.dispose();
  }
} 