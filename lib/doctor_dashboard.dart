import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DoctorDashboard extends StatefulWidget {
  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  String _doctorName = '';
  String _service = '';
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String _selectedSession = 'All';
  List<Map<String, dynamic>> appointments = [];
  bool _isLoading = false;
  int _totalAppointments = 0;
  int _completedAppointments = 0;
  int _pendingAppointments = 0;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _serviceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _loadDoctorProfile();
    _initializeFCM();
    _fetchAppointmentStats();
    _fetchTodaysAppointments();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  Future<void> _initializeFCM() async {
    // Request permission for iOS if necessary
    await _firebaseMessaging.requestPermission();

    // Configure Firebase messaging
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground notifications
      if (message.notification != null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(message.notification!.title ?? 'Notification'),
              content: Text(message.notification!.body ?? 'You have a new update'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Ok'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  Future<void> _loadDoctorProfile() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doctorDoc = await _firestore.collection('doctors').doc(user.uid).get();
      if (doctorDoc.exists) {
        Map<String, dynamic>? doctorData = doctorDoc.data() as Map<String, dynamic>?;
        if (doctorData != null) {
          setState(() {
            _doctorName = doctorData['doctors'] ?? 'No doctor';
            _service = doctorData['service'] ?? 'No Service';
            _nameController.text = _doctorName;
            _serviceController.text = _service;
          });
        } else {
          print('Doctor data is null');
        }
      } else {
        print('Doctor document does not exist');
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('doctors').doc(user.uid).update({
          'doctor': _nameController.text,
          'service': _serviceController.text,
        });
        setState(() {
          _doctorName = _nameController.text;
          _service = _serviceController.text;
        });
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
      }
    }
  }

  Future<void> _fetchAppointmentStats() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final QuerySnapshot allAppointments = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: user.uid)
          .get();

      final QuerySnapshot completedAppointments = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      setState(() {
        _totalAppointments = allAppointments.size;
        _completedAppointments = completedAppointments.size;
        _pendingAppointments = _totalAppointments - _completedAppointments;
      });
    }
  }

  Future<void> _fetchTodaysAppointments() async {
    setState(() => _isLoading = true);
    try {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));

      final QuerySnapshot querySnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: _auth.currentUser?.uid)
          .where('dateTime', isGreaterThanOrEqualTo: today)
          .where('dateTime', isLessThanOrEqualTo: tomorrow)
          .orderBy('dateTime')
          .get();

      setState(() {
        appointments = querySnapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching appointments: $e')),
      );
    }
  }

  Future<void> _markAppointmentComplete(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      await _sendNotification(appointmentId, 'Your appointment has been completed.');
      _fetchAppointmentStats();
      _fetchTodaysAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking appointment complete: $e')),
      );
    }
  }

  Future<void> _rescheduleAppointment(String appointmentId, DateTime newDateTime) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'date': newDateTime.toIso8601String(),
        'time': DateFormat('HH:mm').format(newDateTime),
      });

      // Send a notification after rescheduling
      await _sendNotification(appointmentId, 'Your appointment has been rescheduled.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment rescheduled successfully')),
      );
      _fetchTodaysAppointments();
    } catch (e) {
      print('Error rescheduling appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reschedule appointment')),
      );
    }
  }

  Future<void> _sendNotification(String appointmentId, String message) async {
    try {
      // You should trigger this via Firebase Cloud Functions or your backend, not directly in Flutter.
      // Send a notification to the topic related to the appointment ID using your server or Firebase Cloud Functions
      print("Send notification: $message for appointment $appointmentId");

      // If you're using Firebase Cloud Functions:
      // 1. Send the message from Cloud Functions to the patient (this can be done using Firebase Admin SDK)
      // Example structure of the notification could be handled in the backend instead of within the Flutter app.
      // For now, you can log a message to test.

    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment cancelled successfully')),
      );
      _fetchTodaysAppointments();
    } catch (e) {
      print('Error cancelling appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel appointment')),
      );
    }
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Profile'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _serviceController,
                  decoration: InputDecoration(labelText: 'Service'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your service';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: _updateProfile,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. $_doctorName\'s Dashboard'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showDatePicker(),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditProfileDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchAppointmentStats();
          await _fetchTodaysAppointments();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCards(),
                const SizedBox(height: 20),
                _buildAppointmentFilters(),
                const SizedBox(height: 20),
                _buildAppointmentsList(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generateReport(),
        label: const Text('Generate Report'),
        icon: const Icon(Icons.description),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('Total', _totalAppointments, Colors.blue),
        _buildStatCard('Completed', _completedAppointments, Colors.green),
        _buildStatCard('Pending', _pendingAppointments, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentFilters() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedSession,
            decoration: const InputDecoration(
              labelText: 'Session',
              border: OutlineInputBorder(),
            ),
            items: ['All', 'Morning', 'Afternoon', 'Evening']
                .map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSession = value!;
                _fetchTodaysAppointments();
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showDatePicker,
        ),
      ],
    );
  }

  Widget _buildAppointmentsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appointments.isEmpty) {
      return const Center(
        child: Text('No appointments found for the selected criteria.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(appointment['patientName'] ?? 'Unknown Patient'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Time: ${DateFormat('hh:mm a').format(
                  (appointment['dateTime'] as Timestamp).toDate(),
                )}'),
                Text('Status: ${appointment['status'] ?? 'pending'}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (appointment['status'] != 'completed')
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    color: Colors.green,
                    onPressed: () => _markAppointmentComplete(appointment['id']),
                  ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showAppointmentOptions(appointment),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAppointmentOptions(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_calendar),
            title: const Text('Reschedule'),
            onTap: () {
              Navigator.pop(context);
              _showRescheduleDialog(appointment);
            },
          ),
          ListTile(
            leading: const Icon(Icons.note_add),
            title: const Text('Add Notes'),
            onTap: () {
              Navigator.pop(context);
              _showAddNotesDialog(appointment);
            },
          ),
          if (appointment['status'] != 'completed')
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Mark Complete'),
              onTap: () {
                Navigator.pop(context);
                _markAppointmentComplete(appointment['id']);
              },
            ),
          ListTile(
            leading: const Icon(Icons.cancel),
            title: const Text('Cancel Appointment'),
            onTap: () {
              Navigator.pop(context);
              _showCancelConfirmation(appointment['id']);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport() async {
    final pdf = pw.Document();
    
    final data = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: _auth.currentUser?.uid)
        .orderBy('dateTime', descending: true)
        .get();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Appointments Report'),
              ),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Patient', 'Date', 'Time', 'Status'],
                  ...data.docs.map(
                    (doc) {
                      final data = doc.data();
                      final dateTime = (data['dateTime'] as Timestamp).toDate();
                      return [
                        data['patientName'] ?? 'Unknown',
                        DateFormat('yyyy-MM-dd').format(dateTime),
                        DateFormat('HH:mm').format(dateTime),
                        data['status'] ?? 'pending',
                      ];
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'appointments_report.pdf',
    );
  }

  Future<void> _showRescheduleDialog(Map<String, dynamic> appointment) async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date != null) {
                  selectedDate = date;
                }
              },
              child: const Text('Select Date'),
            ),
            TextButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  selectedTime = time;
                }
              },
              child: const Text('Select Time'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rescheduleAppointment(
                appointment['id'],
                DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                ),
              );
            },
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddNotesDialog(Map<String, dynamic> appointment) async {
    final notesController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Notes'),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter appointment notes...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestore
                  .collection('appointments')
                  .doc(appointment['id'])
                  .update({
                'notes': notesController.text,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              _fetchTodaysAppointments();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelConfirmation(String appointmentId) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelAppointment(appointmentId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
        _fetchTodaysAppointments();
      });
    }
  }
}
