import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientName;
  final String phoneNumber;
  final int age;
  final String county;
  final String idNumber;
  final String serviceId;
  final String doctorId;
  final DateTime dateTime;
  final String session;

  Appointment({
    required this.id,
    required this.patientName,
    required this.phoneNumber,
    required this.age,
    required this.county,
    required this.idNumber,
    required this.serviceId,
    required this.doctorId,
    required this.dateTime,
    required this.session,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      patientName: map['patientName'],
      phoneNumber: map['phoneNumber'],
      age: map['age'],
      county: map['county'],
      idNumber: map['idNumber'],
      serviceId: map['serviceId'],
      doctorId: map['doctorId'],
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      session: map['session'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientName': patientName,
      'phoneNumber': phoneNumber,
      'age': age,
      'county': county,
      'idNumber': idNumber,
      'serviceId': serviceId,
      'doctorId': doctorId,
      'dateTime': dateTime,
      'session': session,
    };
  }
} 