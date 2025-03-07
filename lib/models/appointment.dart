import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String? id;
  final String patientId;
  final String patientName;
  final String phoneNumber;
  final int age;
  final String county;
  final String idNumber;
  final String serviceId;
  final String doctorId;
  final String session;
  final DateTime dateTime;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Appointment({
    this.id,
    required this.patientId,
    required this.patientName,
    required this.phoneNumber,
    required this.age,
    required this.county,
    required this.idNumber,
    required this.serviceId,
    required this.doctorId,
    required this.session,
    required this.dateTime,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt, required String service,
  });

  factory Appointment.fromMap(Map<String, dynamic> map, {String? id}) {
    return Appointment(
      id: id ?? map['id'],
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      age: (map['age'] ?? 0).toInt(),
      county: map['county'] ?? '',
      idNumber: map['idNumber'] ?? '',
      serviceId: map['serviceId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      session: map['session'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(), service: '',
    );
  }

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'phoneNumber': phoneNumber,
      'age': age,
      'county': county,
      'idNumber': idNumber,
      'serviceId': serviceId,
      'doctorId': doctorId,
      'session': session,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  // Add a copyWith method for convenience
  Appointment copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? phoneNumber,
    int? age,
    String? county,
    String? idNumber,
    String? serviceId,
    String? doctorId,
    String? session,
    DateTime? dateTime,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      age: age ?? this.age,
      county: county ?? this.county,
      idNumber: idNumber ?? this.idNumber,
      serviceId: serviceId ?? this.serviceId,
      doctorId: doctorId ?? this.doctorId,
      session: session ?? this.session,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt, service: '',
    );
  }
}